# Import d'une ferme depuis une archive de tenant (point 1.21, tel que la
# décision du 15 septembre l'a redéfini).
#
# La V6 ne reprend pas la base de la V5 en place : les données d'un client
# arrivent par **dump de tenant**, restauré une ferme à la fois. Ce n'est donc
# pas une bascule mais un chemin permanent, et il tient en trois temps :
#
#   1. l'archive est restaurée dans un schéma d'accueil temporaire, par la
#      méthode existante — celle qui sait lire les archives v2 comme v3 ;
#   2. les lignes sont recopiées dans le mono-schéma sous le slug du client,
#      avec le remappage des clés et l'horodatage des uuid ;
#   3. le schéma d'accueil est jeté.
#
#   rake monoschema:import ARCHIVE=tmp/archives/phaurigot.zip SLUG=phaurigot
#
# Le schéma d'accueil porte un nom dérivé, jamais celui du client : deux imports
# simultanés ne se marchent pas dessus, et un import qui échoue ne laisse pas un
# schéma à moitié rempli sous un nom qui ferait croire à une ferme installée.

module MonoschemaImport
  module_function

  def connection
    ActiveRecord::Base.connection
  end

  def staging_name(slug)
    "import_#{slug.gsub(/[^a-z0-9]/, '_')}_#{Time.current.to_i.to_s(36)}"
  end

  # Le nom du schéma que l'archive porte en elle. Une archive v3 ne se restaure
  # que sous ce nom-là — elle qualifie chaque objet.
  def archive_tenant(path)
    Zip::File.open(path) do |zip|
      entry = zip.find_entry('manifest.yml')
      raise "Archive sans manifeste : #{path}" if entry.nil?

      # Le manifeste porte des horodatages : `unsafe_load` est ici sans risque
      # — l'archive vient d'un dump que l'on a produit — et `safe_load`
      # buterait sur `ActiveSupport::TimeWithZone`.
      YAML.unsafe_load(entry.get_input_stream.read).symbolize_keys[:tenant]
    end
  end

  # Restaurer sous le nom d'origine, puis renommer : c'est le seul chemin sûr.
  # Réécrire le SQL pour y substituer le nom du schéma abîmerait les données qui
  # contiennent la même chaîne — une adresse de courriel suffit.
  def restore(archive, staging)
    path = Pathname.new(archive)
    raise "Archive introuvable : #{archive}" unless path.exist?

    source = archive_tenant(path)
    if connection.select_value("SELECT 1 FROM information_schema.schemata WHERE schema_name = #{connection.quote(source)}")
      raise "Le schéma #{source} existe déjà : la restauration l'écraserait. " \
            'Le renommer ou le supprimer avant d’importer.'
    end

    Ekylibre::Tenant.restore(path, tenant: source, verbose: false)
    connection.execute(%(ALTER SCHEMA "#{source}" RENAME TO "#{staging}"))
    Ekylibre::Tenant.drop(source) if Ekylibre::Tenant.exist?(source)
    staging
  end

  # Le schéma d'accueil naît d'un `ALTER SCHEMA ... RENAME`, donc il n'est
  # inscrit nulle part : `Ekylibre::Tenant.drop` ne le voit pas — il lit la
  # liste des tenants, pas la base. On le jette directement, sinon il reste 254
  # tables derrière chaque import.
  def discard(staging)
    return if staging.blank?

    connection.execute(%(DROP SCHEMA IF EXISTS "#{staging}" CASCADE))
  rescue StandardError => e
    warn "  le schéma d'accueil #{staging} n'a pas pu être jeté : #{e.message.lines.first.strip}"
  end

  # Ce qu'un import laisserait derrière lui tant que les référentiels ne sont
  # pas repris. Les quatre tables « à déplacer vers le lexicon » ne sont pas
  # recopiées — leur contenu rejoint une table du référentiel —, si bien que
  # les colonnes qui les désignaient pointent dans le vide. Mesuré sur la ferme
  # de démonstration : 1 486 lignes pour les seules unités.
  def pending_references(staging)
    plan = YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
    relocated = plan.select { |_table, entry| entry['status'] == 'à déplacer vers le lexicon' }.keys

    relocated.filter_map do |table|
      count = connection.select_value(%(SELECT count(*) FROM "#{staging}".#{table})).to_i
      next if count.zero?

      [table, count]
    end.to_h
  rescue StandardError
    {}
  end

  def run(archive:, slug:)
    staging = staging_name(slug)
    started = Time.current

    restore(archive, staging)
    restored = Time.current

    pending = pending_references(staging)
    if pending.any? && ENV['FORCE'].blank?
      lines = pending.map { |table, count| "    #{table} : #{count} lignes" }
      raise <<~TEXT
        Cette ferme porte des référentiels qui ne sont pas encore repris au Lexicon :
        #{lines.join("\n")}
        Ils ne seront pas recopiés, et les colonnes qui les désignent pointeront
        dans le vide. Reprendre ces référentiels au Lexicon d'abord, ou passer
        FORCE=1 en sachant que la ferme devra être réimportée ensuite.
      TEXT
    end

    result = MonoschemaMigration.run(staging => slug)
    copied = Time.current

    { staging: staging, rows: result[:counts].values.sum,
      restore_duration: (restored - started).round(1),
      copy_duration: (copied - restored).round(1) }
  ensure
    discard(staging)
  end
end

namespace :monoschema do
  desc 'Importe une ferme depuis une archive de tenant (ARCHIVE=, SLUG=)'
  task import: :environment do
    archive = ENV.fetch('ARCHIVE', nil)
    slug = ENV.fetch('SLUG', nil)
    abort 'ARCHIVE=chemin.zip et SLUG=nom attendus' if archive.blank? || slug.blank?

    result = MonoschemaImport.run(archive: archive, slug: slug)
    puts "  ferme #{slug} : #{result[:rows]} lignes"
    puts "  restauration de l'archive : #{result[:restore_duration]} s"
    puts "  recopie vers le mono-schéma : #{result[:copy_duration]} s"
  end
end
