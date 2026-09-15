# Inventaire du SQL brut (point 1.19).
#
# Le lot 1 change deux choses sous les pieds du SQL écrit à la main : les tables
# du plan de données portent un `tenant_id NOT NULL`, et leur clé primaire
# devient composite. Cette tâche recense les sites concernés et les classe par
# ce qui leur arrivera — pas par la syntaxe qu'ils emploient.
#
#   rake monoschema:raw_sql
#
# Ce que la Row Level Security règle déjà, et qu'il ne faut donc pas chercher
# ici : une requête brute posée sous un contexte de ferme est filtrée comme les
# autres, y compris ses jointures — deux tables filtrées chacune sur la même
# ferme ne peuvent pas se joindre entre fermes. Le SQL brut n'est pas un trou
# dans l'isolation ; il est un candidat à la *rupture*.

module MonoschemaRawSql
  OUTPUT_PATH = 'db/monoschema/raw-sql.yml'.freeze
  GLOBS = %w[app/**/*.rb lib/**/*.rb].freeze

  # Ce qu'on cherche, et ce que ça devient.
  PATTERNS = {
    'écriture brute' => /\b(?:INSERT\s+INTO|COPY\s+\w+\s+FROM)\b/i,
    'conflit sur index unique' => /\bON\s+CONFLICT\b/i,
    'exécution libre' => /connection\.execute\b/,
    'lecture libre' => /connection\.(?:select_all|select_one|select_value|select_rows)\b|find_by_sql\b/,
    'écriture en masse' => /\.update_all\b|\.delete_all\b/,
    'jointure écrite à la main' => /\.joins\(\s*["']/
  }.freeze

  module_function

  def plan
    @plan ||= YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
  end

  def data_tables
    @data_tables ||= plan.select { |_table, entry| entry['plane'] == 'data' }.keys.to_set
  end

  def sites
    GLOBS.flat_map { |glob| Dir[Rails.root.join(glob)].sort }.flat_map { |path| sites_in(path) }
  end

  def sites_in(path)
    relative = Pathname.new(path).relative_path_from(Rails.root).to_s
    File.readlines(path).each_with_index.filter_map do |line, index|
      kind = PATTERNS.find { |_name, pattern| line.match?(pattern) }&.first
      next if kind.nil?

      { 'site' => "#{relative}:#{index + 1}", 'cas' => kind, 'tables' => tables_in(line), 'source' => line.strip[0, 160] }
    end
  end

  def tables_in(line)
    data_tables.select { |table| line.match?(/\b#{table}\b/) }.sort
  end

  # Le classement est celui de la conséquence, pas de la syntaxe.
  def consequence(site)
    case site['cas']
    when 'écriture brute'
      # Mesuré : « new row violates row-level security policy » — la politique
      # est évaluée avant la contrainte NOT NULL, mais l'échec est bruyant dans
      # les deux cas.
      'à reprendre : un INSERT doit désormais fournir tenant_id, sinon la politique le refuse'
    when 'conflit sur index unique'
      # Mesuré : « there is no unique or exclusion constraint matching the ON
      # CONFLICT specification ».
      'à reprendre : les index uniques commencent par tenant_id, la cible du ON CONFLICT change'
    when 'écriture en masse'
      'à relire : Rails 8.1 compile un update_all joint en UPDATE … FROM, et la clé composite change la clause'
    when 'jointure écrite à la main'
      site['tables'].size > 1 ? 'à relire : jointure entre tables du plan de données, à porter sur (tenant_id, id)' : 'sans objet sous RLS'
    else
      site['tables'].empty? ? 'sans objet : ne touche aucune table du plan de données' : 'sans objet sous RLS : la politique filtre aussi le SQL brut'
    end
  end

  def build
    inventory = sites.map { |site| site.merge('conséquence' => consequence(site)) }
    path = Rails.root.join(OUTPUT_PATH)
    path.write(<<~HEADER + inventory.to_yaml.sub(/\A---\n/, ''))
      # ENGENDRÉ PAR `rake monoschema:raw_sql` — NE PAS MODIFIER À LA MAIN.
      #
      # Les sites de SQL écrit à la main, classés par ce qui leur arrive dans le
      # mono-schéma. « sans objet sous RLS » ne veut pas dire « sans risque » :
      # cela veut dire que la politique les couvre tant qu'un contexte de ferme
      # est posé — ce que le point 1.17 garantit.
      #
    HEADER
    inventory
  end

  def summary(inventory)
    inventory.group_by { |site| site['conséquence'].split(' :').first }
             .transform_values(&:size)
             .sort_by { |_key, value| -value }
  end
end

namespace :monoschema do
  desc 'Recense le SQL brut et ce que le mono-schéma lui fait'
  task raw_sql: :environment do
    inventory = MonoschemaRawSql.build
    puts "#{MonoschemaRawSql::OUTPUT_PATH} engendré : #{inventory.size} sites."
    MonoschemaRawSql.summary(inventory).each { |label, count| puts format('  %<count>4d  %<label>s', count: count, label: label) }

    to_fix = inventory.reject { |site| site['conséquence'].start_with?('sans objet') }
    puts "\n#{to_fix.size} sites à reprendre ou relire :"
    to_fix.first(15).each { |site| puts "  #{site['site']}  #{site['cas']}" }
    puts "  … et #{to_fix.size - 15} autres" if to_fix.size > 15
  end
end
