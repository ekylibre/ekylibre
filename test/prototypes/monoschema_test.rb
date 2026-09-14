# Prototype de mono-schéma — point 1.4 de la feuille de route v6.
#
# Ce fichier est la mesure du prototype : il vérifie sur une vraie base ce que
# l'ADR-002 et l'ADR-003 affirment, plutôt que de le supposer. Ce qu'il établit
# est consigné dans db/prototypes/monoschema/README.md.
#
# La base de sonde est montée par `rake monoschema:build` et n'existe pas
# ailleurs : sans elle, ces tests sont ignorés — ils ne doivent pas mettre la
# suite au rouge sur un poste qui n'a pas joué la tâche.
#
#   bundle exec rake monoschema:generate monoschema:build
#   bundle exec ruby -Itest test/prototypes/monoschema_test.rb

require File.expand_path('../../config/environment', __dir__)
require 'minitest/autorun'

module Monoschema
  DATABASE = ENV.fetch('MONOSCHEMA_DATABASE', 'ekylibre_monoschema')
  APP_ROLE = ENV.fetch('MONOSCHEMA_APP_ROLE', 'ekylibre_app')
  APP_PASSWORD = ENV.fetch('MONOSCHEMA_APP_PASSWORD', 'ekylibre_app')

  def self.configuration
    configurations = Rails.application.config.database_configuration
    # L'environnement courant, pas `development` : la CI ne configure que
    # `test` (voir test/ci/database.yml).
    host_config = configurations[Rails.env] || configurations['development']
    {
      'adapter' => 'postgis',
      'host' => host_config['host'].presence || 'db',
      'port' => host_config['port'],
      'database' => DATABASE,
      # Le rôle applicatif, pas le propriétaire : c'est la condition de
      # l'ADR-002. Un propriétaire échapperait à la politique sans `FORCE`, et
      # pourrait la désactiver avec.
      'username' => APP_ROLE,
      'password' => APP_PASSWORD,
      'schema_search_path' => 'ekylibre,public,postgis'
    }
  end

  def self.available?
    return @available if defined?(@available)

    @available = begin
      Record.connection.select_value('SELECT 1')
      true
    rescue StandardError
      false
    end
  end

  class Record < ActiveRecord::Base
    self.abstract_class = true
  end

  class Tenant < Record
    self.table_name = 'tenants'
  end

  # Clé primaire composite native : c'est le schéma qui la déclare, et Rails
  # 8.1 la déduit seul. Aucune annotation n'est nécessaire ici — c'est
  # précisément ce que le prototype veut vérifier.
  class Intervention < Record
    self.table_name = 'interventions'

    # `query_constraints:` n'est pas accepté sur une association en Rails 8.1 —
    # il lève « To get the same behavior, use the `foreign_key` option
    # instead ». La clé étrangère composite se déclare donc en tableau.
    has_many :parameters, class_name: 'Monoschema::InterventionParameter',
                          foreign_key: %i[tenant_id intervention_id]
  end

  class InterventionParameter < Record
    self.table_name = 'intervention_parameters'

    belongs_to :intervention, class_name: 'Monoschema::Intervention',
                              foreign_key: %i[tenant_id intervention_id]
    belongs_to :product, class_name: 'Monoschema::Product',
                         foreign_key: %i[tenant_id product_id], optional: true
  end

  class Product < Record
    self.table_name = 'products'
    # Les types stockés sont ceux de l'application (`Plant`, `Equipment`), pas
    # des noms qualifiés : le prototype garde la donnée telle quelle.
    self.store_full_sti_class = false
  end

  class Plant < Product; end
  class Equipment < Product; end

  # L'équivalent du futur `TenantRecord` : une transaction, un `SET LOCAL`, et
  # le contexte meurt avec elle. `SET` et non `SET LOCAL` fuirait vers la
  # requête suivante du pool (ADR-002).
  # Le cache de requêtes est indexé sur le texte SQL seul : il ne sait rien du
  # tenant. Changer de contexte sans le vider rend les lignes du précédent —
  # mesuré, voir le test « le cache de requêtes ne connaît pas le tenant ».
  def self.with_tenant(tenant_id, &block)
    Record.connection.clear_query_cache
    Record.transaction do
      Record.connection.execute("SET LOCAL app.tenant_id = #{Record.connection.quote(tenant_id)}")
      block.call
    end
  ensure
    Record.connection.clear_query_cache
  end

  def self.without_tenant(&block)
    Record.connection.clear_query_cache
    Record.transaction do
      Record.connection.execute('SET LOCAL app.tenant_id = DEFAULT')
      block.call
    end
  ensure
    Record.connection.clear_query_cache
  end
end

Monoschema::Record.establish_connection(Monoschema.configuration)

class MonoschemaTest < ActiveSupport::TestCase
  ALPHA = '11111111-1111-7111-8111-111111111111'.freeze
  BETA  = '22222222-2222-7222-8222-222222222222'.freeze

  def setup
    skip "base #{Monoschema::DATABASE} absente — lancer `rake monoschema:build`" unless Monoschema.available?
    seed unless self.class.seeded
    self.class.seeded = true
  end

  class << self
    attr_accessor :seeded
  end

  # --- Isolation ----------------------------------------------------------

  test 'sans contexte de tenant, la base ne rend aucune ligne' do
    Monoschema.without_tenant do
      assert_equal 0, Monoschema::Product.count
      assert_equal 0, Monoschema::Intervention.count
      assert_equal 0, Monoschema::InterventionParameter.count
    end
  end

  test 'chaque tenant ne voit que ses propres lignes' do
    Monoschema.with_tenant(ALPHA) do
      assert_equal %w[ALPHA-1 ALPHA-2], named_products.order(:number).pluck(:number)
    end
    Monoschema.with_tenant(BETA) do
      assert_equal %w[BETA-1], named_products.order(:number).pluck(:number)
    end
  end

  test 'une ligne du voisin reste introuvable, même désignée par sa clé' do
    beta_id = Monoschema.with_tenant(BETA) { Monoschema::Product.first.id_value }

    Monoschema.with_tenant(ALPHA) do
      assert_nil Monoschema::Product.find_by(id: beta_id)
      assert_raises(ActiveRecord::RecordNotFound) { Monoschema::Product.find([BETA, beta_id]) }
    end
  end

  test 'écrire une ligne chez le voisin est refusé par WITH CHECK' do
    error = assert_raises(ActiveRecord::StatementInvalid) do
      Monoschema.with_tenant(ALPHA) do
        Monoschema::Product.create!(product_attributes(BETA, 'INTRUS'))
      end
    end
    assert_match(/row-level security/, error.message)
  end

  test 'déplacer une ligne chez le voisin est refusé de même' do
    error = assert_raises(ActiveRecord::StatementInvalid) do
      Monoschema.with_tenant(ALPHA) do
        Monoschema::Product.find_by!(number: 'ALPHA-1').update!(tenant_id: BETA)
      end
    end
    assert_match(/row-level security/, error.message)
  end

  test 'le contexte meurt avec la transaction' do
    Monoschema.with_tenant(ALPHA) { assert_operator Monoschema::Product.count, :>, 0 }

    # Hors transaction, sur la même connexion du pool : `SET LOCAL` n'a rien
    # laissé derrière lui, donc la politique ne laisse rien passer.
    assert_equal 0, Monoschema::Product.count
  end

  test 'le cache de requêtes peut resservir les lignes lues sous un autre contexte' do
    conn = Monoschema::Record.connection
    sql = 'SELECT count(*) FROM ekylibre.products'

    inside, outside = conn.cache do
      # Volontairement sans vidage : c'est la démonstration du piège. Le cache
      # est indexé sur le seul texte SQL, il ignore `app.tenant_id`.
      under_tenant = conn.transaction do
        conn.execute("SET LOCAL app.tenant_id = #{conn.quote(ALPHA)}")
        conn.select_value(sql)
      end
      # Hors transaction, donc hors contexte : la politique ne devrait rien
      # laisser passer, et pourtant le cache repond.
      [under_tenant, conn.select_value(sql)]
    end

    assert_operator inside, :>, 0
    assert_equal inside, outside,
                 'le cache devrait resservir le compte du tenant A hors de tout contexte'
    # `uncached` et non « hors du bloc » : le cache est actif par défaut sur
    # cette connexion, le bloc ne faisait que le rendre visible.
    conn.uncached { assert_equal 0, conn.select_value(sql), 'hors cache, la fermeture par defaut doit jouer' }
  end

  test 'vider le cache au changement de contexte suffit à rétablir la vérité' do
    Monoschema::Record.connection.cache do
      alpha = Monoschema.with_tenant(ALPHA) { named_products.order(:number).pluck(:number) }
      beta = Monoschema.with_tenant(BETA) { named_products.order(:number).pluck(:number) }

      assert_equal %w[ALPHA-1 ALPHA-2], alpha
      assert_equal %w[BETA-1], beta
    end
  end

  test "le rôle applicatif ne peut pas désactiver la politique" do
    error = assert_raises(ActiveRecord::StatementInvalid) do
      Monoschema::Record.connection.execute('ALTER TABLE ekylibre.products DISABLE ROW LEVEL SECURITY')
    end
    assert_match(/must be owner of table products/, error.message)
  end

  # --- Intégrité ----------------------------------------------------------

  test 'une référence vers le voisin est refusée par la clé étrangère composite' do
    beta_intervention = Monoschema.with_tenant(BETA) { Monoschema::Intervention.first.id_value }

    error = assert_raises(ActiveRecord::StatementInvalid) do
      Monoschema.with_tenant(ALPHA) do
        Monoschema::InterventionParameter.create!(
          tenant_id: ALPHA, intervention_id: beta_intervention, reference_name: 'intrus',
          position: 1, created_at: Time.zone.now, updated_at: Time.zone.now
        )
      end
    end
    assert_match(/foreign key constraint/, error.message)
  end

  test 'le même numéro de produit peut exister chez deux fermes' do
    Monoschema.with_tenant(ALPHA) do
      Monoschema::Product.create!(product_attributes(ALPHA, 'PARTAGÉ'))
    end
    Monoschema.with_tenant(BETA) do
      assert_nothing_raised { Monoschema::Product.create!(product_attributes(BETA, 'PARTAGÉ')) }
    end

    error = assert_raises(ActiveRecord::RecordNotUnique) do
      Monoschema.with_tenant(ALPHA) do
        Monoschema::Product.create!(product_attributes(ALPHA, 'PARTAGÉ'))
      end
    end
    assert_match(/index_products_on_number/, error.message)
  ensure
    # La base de sonde ne roule pas en arrière entre deux tests : ce qu'un test
    # crée, il le retire. C'est la leçon du point 0.2, appliquée d'emblée.
    [ALPHA, BETA].each do |tenant_id|
      Monoschema.with_tenant(tenant_id) { Monoschema::Product.where(number: 'PARTAGÉ').delete_all }
    end
  end

  # --- Clés et associations -----------------------------------------------

  test 'Rails déduit la clé primaire composite du schéma' do
    assert_equal %w[tenant_id id], Monoschema::Product.primary_key
    assert_equal %w[tenant_id id], Monoschema::Intervention.primary_key
  end

  test '`id` rend le couple, la colonne se lit par `id_value`' do
    Monoschema.with_tenant(ALPHA) do
      product = Monoschema::Product.find_by!(number: 'ALPHA-1')

      assert_kind_of Array, product.id
      assert_equal [ALPHA, product.id_value], product.id
      assert_kind_of Integer, product.id_value
    end
  end

  test 'les associations traversent la clé composite' do
    Monoschema.with_tenant(ALPHA) do
      intervention = Monoschema::Intervention.first
      sql = intervention.parameters.to_sql

      assert_includes sql, 'tenant_id'
      assert_equal 2, intervention.parameters.count
      assert_equal 'ALPHA-1', intervention.parameters.order(:position).first.product.number
    end
  end

  test 'uuidv7 est engendré par la base et croît avec le temps' do
    ids = Monoschema.with_tenant(ALPHA) do
      3.times.map { Monoschema::Intervention.create!(intervention_attributes(ALPHA)).id_value }
    end

    assert_equal 3, ids.uniq.size
    assert_equal ids, ids.sort, 'les UUIDv7 doivent se suivre dans l’ordre de création'
    assert_equal '7', ids.first[14], 'la version doit être 7'
  end

  test 'le STI continue de fonctionner sous clé composite' do
    Monoschema.with_tenant(ALPHA) do
      assert_equal %w[ALPHA-1], named_products.where(type: 'Plant').order(:number).pluck(:number)
      assert_includes Monoschema::Plant.all.to_sql, %q("products"."type" = 'Plant')
      assert_kind_of Monoschema::Plant, Monoschema::Product.find_by(number: 'ALPHA-1')
    end
  end

  test 'le verrou optimiste tient sous clé composite' do
    Monoschema.with_tenant(ALPHA) do
      product = Monoschema::Product.find_by!(number: 'ALPHA-2')
      stale = Monoschema::Product.find_by!(number: 'ALPHA-2')

      product.update!(name: 'premier écrivain')
      stale.name = 'second écrivain'

      assert_raises(ActiveRecord::StaleObjectError) { stale.save! }
    end
  end

  # --- Plan d'exécution ---------------------------------------------------

  test "l'index GiST composite sert la requête parcellaire d'un tenant" do
    plan = Monoschema.with_tenant(ALPHA) do
      Monoschema::Record.connection.select_values(<<~SQL).join("\n")
        EXPLAIN SELECT count(*) FROM ekylibre.products
         WHERE tenant_id = '#{ALPHA}'
           AND postgis.ST_Intersects(initial_shape, postgis.ST_MakeEnvelope(0.10, 44.10, 0.12, 44.12, 4326))
      SQL
    end

    # `ST_Intersects` se déplie en `&& AND _ST_Intersects(...)`, et c'est le `&&`
    # qui devient condition d'index. Deux conditions à cela, apprises ici :
    # la table doit être analysée — sans statistiques le planificateur estime la
    # sélectivité spatiale au jugé et préfère n'importe quel btree préfixé par
    # `tenant_id` —, et le parcours par bitmap doit rester permis, puisque c'est
    # par lui que passe un index GiST.
    assert_match(/index_products_on_tenant_and_initial_shape/, plan,
                 "le plan devrait passer par l'index GiST composite :\n#{plan}")
  end

  test 'les opérateurs spatiaux sont marqués LEAKPROOF' do
    marks = Monoschema::Record.connection.select_values(<<~SQL)
      SELECT p.proleakproof
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'postgis'
         AND p.proname IN ('geometry_overlaps', 'st_intersects')
         -- La surcharge geometry/geometry seule : `st_intersects` en porte
         -- trois, dont une geography et une text.
         AND pg_get_function_identity_arguments(p.oid) LIKE '%postgis.geometry, %postgis.geometry'
    SQL

    assert marks.all?, <<~TEXT
      Sous RLS, une condition non LEAKPROOF est évaluée après la politique et ne
      peut pas servir d'index. Sans ce marquage, la requête parcellaire passe
      d'un coût estimé de 229 à 63 380 sur le jeu du prototype — l'index GiST
      composite existe mais ne sert plus.
    TEXT
  end

  private

    # Les lignes de volume, semées pour donner au planificateur de quoi choisir,
    # n'ont pas à encombrer les assertions d'isolation.
    def named_products
      Monoschema::Product.where.not('number LIKE ?', 'MASSE-%')
    end

    def seed
      seed_tenants
      # La base de sonde n'est pas jetée entre deux exécutions : on repart des
      # mêmes données à chaque fois. Les suppressions passent par la politique,
      # ce qui vérifie au passage qu'un DELETE ne franchit pas le tenant.
      [ALPHA, BETA].each do |tenant_id|
        Monoschema.with_tenant(tenant_id) do
          Monoschema::InterventionParameter.delete_all
          Monoschema::Intervention.delete_all
          Monoschema::Product.delete_all
        end
      end

      Monoschema.with_tenant(ALPHA) do
        Monoschema::Plant.create!(product_attributes(ALPHA, 'ALPHA-1'))
        Monoschema::Equipment.create!(product_attributes(ALPHA, 'ALPHA-2'))
        intervention = Monoschema::Intervention.create!(intervention_attributes(ALPHA))
        product = Monoschema::Product.find_by!(number: 'ALPHA-1')
        2.times do |index|
          # `id` rend le couple complet sous clé composite : la colonne se lit
          # par `id_value`. C'est le piège n° 1 du portage (voir le test dédié).
          Monoschema::InterventionParameter.create!(
            tenant_id: ALPHA, intervention_id: intervention.id_value, product_id: product.id_value,
            reference_name: "cible-#{index}", position: index + 1,
            created_at: Time.zone.now, updated_at: Time.zone.now
          )
        end
        seed_volume(ALPHA)
      end

      Monoschema.with_tenant(BETA) do
        Monoschema::Plant.create!(product_attributes(BETA, 'BETA-1'))
        Monoschema::Intervention.create!(intervention_attributes(BETA))
        seed_volume(BETA)
      end

      # Sans statistiques, le planificateur estime la selectivite spatiale au
      # doigt mouille et ignore l'index GiST.
      Monoschema::Record.connection.execute('ANALYZE ekylibre.products')
    end

    # Les tenants eux-mêmes sont hors RLS : c'est le plan de contrôle.
    def seed_tenants
      [[ALPHA, 'alpha'], [BETA, 'beta']].each do |id, slug|
        next if Monoschema::Tenant.find_by(id: id)

        Monoschema::Tenant.create!(id: id, slug: slug)
      end
    end

    # Assez de lignes pour que le planificateur ait à choisir : sur trois lignes
    # il balaye la table quoi qu'il arrive, et la mesure ne dirait rien.
    def seed_volume(tenant_id)
      Monoschema::Record.connection.execute(<<~SQL)
        INSERT INTO ekylibre.products
          (tenant_id, type, name, number, variant_id, nature_id, category_id, variety,
           initial_shape, created_at, updated_at)
        SELECT '#{tenant_id}', 'Plant', 'masse ' || i, 'MASSE-#{tenant_id[0, 4]}-' || i, 1, 1, 1, 'plant',
               postgis.ST_Multi(postgis.ST_MakeEnvelope(i % 100 * 0.01, 44 + (i % 100 * 0.01),
                                                        i % 100 * 0.01 + 0.005, 44 + (i % 100 * 0.01) + 0.005, 4326)),
               now(), now()
          FROM generate_series(1, 5000) AS i
      SQL
    end

    def product_attributes(tenant_id, number)
      {
        tenant_id: tenant_id, name: number, number: number, variant_id: 1, nature_id: 1,
        category_id: 1, variety: 'plant', created_at: Time.zone.now, updated_at: Time.zone.now
      }
    end

    def intervention_attributes(tenant_id)
      {
        tenant_id: tenant_id, procedure_name: 'sowing', state: 'done', nature: 'record',
        started_at: Time.zone.now, stopped_at: Time.zone.now, working_duration: 3600,
        whole_duration: 3600, created_at: Time.zone.now, updated_at: Time.zone.now
      }
    end
end
