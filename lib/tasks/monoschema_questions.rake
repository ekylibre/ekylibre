# Questionnaire de classification (point 1.5).
#
# `rake monoschema:questionnaire` engendre docs/planning/v6-classification-questions.md :
# un document à remplir à la main, table par table, pour dire ce que devient
# chaque modèle — conserver au plan de données, passer au référentiel partagé,
# supprimer, ou discuter.
#
# Le document est *engendré* pour que les faits qu'il porte soient mesurés :
# nombre de colonnes, clés étrangères, mentions dans le code, présence d'un
# modèle, de fixtures, date de la dernière migration qui touche la table. Les
# réponses, elles, s'écrivent à la main dans le fichier et sont ensuite
# reportées dans db/monoschema/classification.yml.
#
# Le relancer écrase les réponses : à n'engendrer qu'une fois, ou après avoir
# reporté les réponses.

module MonoschemaQuestions
  OUTPUT_PATH = 'docs/planning/v6-classification-questions.md'.freeze
  SOURCE_GLOBS = %w[app/**/*.rb app/**/*.haml lib/**/*.rb config/**/*.rb config/**/*.yml].freeze

  module_function

  def plan
    @plan ||= YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
  end

  def classification
    @classification ||= YAML.load_file(Rails.root.join(MonoschemaPlan::CLASSIFICATION_PATH))
  end

  # Modèle correspondant à une table, s'il existe. Une table sans modèle est un
  # premier signal : personne ne la lit par ActiveRecord.
  def models_by_table
    @models_by_table ||= begin
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.each_with_object({}) do |model, index|
        next if model.abstract_class?
        next unless model.table_exists?

        index[model.table_name] ||= []
        index[model.table_name] << model.name
      rescue StandardError
        next
      end
    end
  end

  # Le corpus, lu une fois. Compter les mentions fichier par fichier coûterait
  # 241 parcours de l'arbre.
  def corpus
    @corpus ||= SOURCE_GLOBS.flat_map { |glob| Dir[Rails.root.join(glob)] }
                            .reject { |path| path.include?('/app/models/') && path.end_with?('.rb') }
                            .map { |path| File.read(path) }
                            .join("\n")
  end

  def mentions(table, model_names)
    terms = ([table] + Array(model_names)).uniq
    terms.sum { |term| corpus.scan(/\b#{Regexp.escape(term)}\b/).size }
  end

  def fixture_rows(table)
    path = Rails.root.join('test', 'fixtures', "#{table}.yml")
    return nil unless path.exist?

    YAML.unsafe_load_file(path)&.size || 0
  rescue StandardError
    nil
  end

  # La dernière migration qui nomme la table, par son horodatage de fichier :
  # une table dont plus rien ne bouge depuis dix ans se remarque.
  def last_migration(table)
    @migrations ||= Dir[Rails.root.join('db', 'migrate', '*.rb')].to_h { |path| [path, File.read(path)] }
    dates = @migrations.filter_map do |path, content|
      File.basename(path)[/\A(\d{4})(\d{2})/, 0] if content.include?(table)
    end
    return nil if dates.empty?

    dates.max.insert(4, '-')
  end

  def facts(table, entry)
    model_names = models_by_table[table]
    {
      table: table,
      models: model_names,
      columns: entry['columns'],
      foreign_keys: entry['references'].size,
      implicit: entry['implicit_references'].size,
      indexes: entry['indexes'],
      sti: entry['sti'],
      geometry: entry['geometry'].any?,
      id: entry['id'],
      fixtures: fixture_rows(table),
      editable: editable?(table),
      mentions: mentions(table, model_names),
      last_migration: last_migration(table)
    }
  end

  # Trois signaux, trois questions. Ils ne décident de rien : ils disent quelles
  # tables méritent qu'on s'y arrête d'abord.
  def flag(fact)
    return :orphan if fact[:models].nil?
    return :dormant if fact[:mentions] < 15 && fact[:fixtures].to_i.zero?
    return :reference_candidate if reference_candidate?(fact)

    nil
  end

  # La question du référentiel partagé est « une ferme peut-elle modifier ces
  # lignes ? ». Le signal mesurable est l'écran : pas de contrôleur ni de vue
  # dans le backend, donc personne ne les édite depuis l'application.
  def reference_candidate?(fact)
    !fact[:editable] && !fact[:geometry] && fact[:columns] <= 15
  end

  def editable?(table)
    Rails.root.join('app', 'controllers', 'backend', "#{table}_controller.rb").exist? ||
      Rails.root.join('app', 'views', 'backend', table).directory?
  end

  def data_tables
    plan.select { |_table, entry| entry['plane'] == 'data' }
  end

  def build
    facts = data_tables.map { |table, entry| facts(table, entry) }
    path = Rails.root.join(OUTPUT_PATH)
    path.write(document(facts))
    path
  end

  def document(facts)
    flagged = facts.group_by { |fact| flag(fact) }
    <<~MARKDOWN
      #{preamble(facts)}
      #{open_questions}
      #{section('Tables sans modèle ActiveRecord', <<~TEXT, flagged[:orphan])}
        Aucune classe ne les déclare. Soit elles sont mortes, soit elles ne sont
        lues qu'en SQL — ce qui se vérifie dans la colonne « mentions ».
      TEXT
      #{section('Tables peu mentionnées et sans fixtures', <<~TEXT, flagged[:dormant])}
        Moins de quinze mentions dans le code et pas une ligne de fixture. Le
        signal est faible pris seul — une table peut être écrite par un
        exchanger et lue nulle part — mais c'est là que se trouvent les
        candidates à la suppression.
      TEXT
      #{section("Tables qu'aucun écran ne modifie", <<~TEXT, flagged[:reference_candidate])}
        Ni contrôleur ni vue dans le backend : aucune ferme ne les édite depuis
        l'application. C'est la question du référentiel partagé — si la donnée
        est la même pour tous, elle a sa place dans le `lexicon` plutôt que
        recopiée dans chaque ferme.
      TEXT
      #{section('Le reste', <<~TEXT, flagged[nil])}
        Rien ne les signale. Ne rien écrire vaut « conserver au plan de
        données ».
      TEXT
    MARKDOWN
  end

  def preamble(facts)
    <<~MARKDOWN
      # Classification des modèles — questionnaire

      > Engendré par `rake monoschema:questionnaire` le #{I18n.l(Date.current, format: '%-d %B %Y', locale: :fra)}.
      > **Les faits sont mesurés, les réponses sont à écrire à la main.** Une fois
      > le document rempli, ses réponses sont reportées dans
      > `db/monoschema/classification.yml`, qui fait foi.

      Ce document accompagne le point 1.5 de
      [la feuille de route](v6-roadmap.md) : chacune des **#{facts.size} tables du
      plan de données** doit recevoir une décision avant que le générateur de
      migrations du point 1.6 ne les touche.

      **Quatre réponses possibles**, à écrire dans la colonne *Décision* :

      | Réponse | Ce qu'elle veut dire |
      |---|---|
      | *(vide)* ou `conserver` | la table porte les données d'une ferme : `tenant_id`, PK composite, RLS. C'est le défaut |
      | `lexicon` | référentiel partagé entre toutes les fermes, lu seulement. Suppose qu'aucune ferme ne l'édite |
      | `supprimer` | table morte : ni le lot 1 ni la suite n'ont à la porter |
      | `contrôle` | globale sans être un référentiel : infrastructure, identité inter-fermes |
      | `discuter` | la question demande autre chose qu'une réponse en un mot |

      Chaque table n'apparaît qu'une fois, dans la section où un signal l'a
      rangée. La colonne `clé` marque les tables qui recevraient une clé
      **UUIDv7** parce que le terrain peut les créer hors ligne (ADR-003) ;
      écrire `bigint` ou `uuidv7` dans la décision revient sur ce choix, qui est
      le seul irréversible du lot.

      **Comment lire les faits.** `mentions` compte les occurrences du nom de la
      table et de ses modèles dans `app/`, `lib/` et `config/` — le fichier du
      modèle lui-même est exclu, pour qu'une table morte ne se compte pas
      elle-même. `fixtures` donne le nombre de lignes du jeu de test, `—` quand
      il n'y en a pas. `migration` est la dernière migration qui nomme la table.
      `réf.` compte les clés étrangères déclarées, `impl.` les colonnes en `_id`
      qui en tiennent lieu sans contrainte. `écran` dit si le backend porte un
      contrôleur ou des vues pour cette table — donc si une ferme peut la
      modifier.

    MARKDOWN
  end

  def open_questions
    questions = classification.fetch('review', {})
    rows = questions.map { |table, question| "### #{table}\n\n#{question}\n\n**Réponse :**\n" }
    <<~MARKDOWN
      ---

      ## 1. Les #{questions.size} questions déjà ouvertes

      Ce sont celles que la classification a laissées en suspens. Elles
      demandent plus qu'un mot : la réponse attendue est une phrase.

      #{rows.join("\n")}
      ---

      ## 2. Le reste des tables, par ordre d'attention

    MARKDOWN
  end

  def section(title, introduction, facts)
    return "### #{title}\n\n#{introduction}\n*Aucune.*\n" if facts.blank?

    <<~MARKDOWN
      ### #{title} (#{facts.size})

      #{introduction}
      | Table | Modèle | col. | réf. | impl. | mentions | fixtures | écran | migration | clé | Décision |
      |---|---|---:|---:|---:|---:|---:|---|---|---|---|
      #{facts.sort_by { |fact| [-fact[:mentions], fact[:table]] }.map { |fact| row(fact) }.join("\n")}
    MARKDOWN
  end

  def row(fact)
    models = Array(fact[:models]).join(', ').presence || '—'
    models += ' *(STI)*' if fact[:sti]
    models += ' *(géo)*' if fact[:geometry]
    [
      fact[:table], models, fact[:columns], fact[:foreign_keys], fact[:implicit],
      fact[:mentions], fact[:fixtures] || '—', fact[:editable] ? 'oui' : 'non',
      fact[:last_migration] || '—', fact[:id] == 'uuid' ? 'uuidv7' : '', ''
    ].join(' | ').then { |cells| "| #{cells} |" }
  end
end

namespace :monoschema do
  desc 'Engendre le questionnaire de classification à remplir à la main'
  task questionnaire: :environment do
    path = MonoschemaQuestions.build
    puts "#{MonoschemaQuestions::OUTPUT_PATH} engendré (#{path.read.lines.count} lignes)."
    puts 'Les réponses s’écrivent dans ce fichier, puis se reportent dans db/monoschema/classification.yml.'
  end
end
