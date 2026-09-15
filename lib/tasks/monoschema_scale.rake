# Mesure d'échelle (point 1.9, et ce que l'ADR-002 affirme sans l'avoir montré).
#
# Deux fermes prouvent l'isolation ; elles ne disent rien des plans d'exécution.
# Cette tâche peuple la base de sonde de fermes et de lignes, puis regarde ce
# que le planificateur fait des index composites — celui de la clé primaire, et
# le GiST `(tenant_id, shape)` que l'ADR-002 recommande.
#
#   rake monoschema:scale TENANTS=200 ROWS=2000
#
# Ce qu'elle mesure, et pourquoi c'est la bonne question : en schéma par ferme,
# une requête ne voyait que les lignes de sa ferme. En base unique, elle les
# voit toutes et doit les écarter — c'est le seul endroit où le mono-schéma peut
# coûter plus cher que ce qu'il remplace.

module MonoschemaScale
  module_function

  def owner
    MonoschemaAudit.connection
  end

  def application
    MonoschemaIsolation.application
  end

  def populate(tenants, rows)
    owner.execute('SET session_replication_role = replica')
    owner.execute('TRUNCATE ekylibre.products, ekylibre.interventions, ekylibre.intervention_parameters CASCADE')
    owner.execute('DELETE FROM ekylibre.tenant_shares')
    owner.execute('DELETE FROM ekylibre.tenants')

    owner.execute(<<~SQL)
      INSERT INTO ekylibre.tenants (id, slug)
      SELECT uuidv7(), 'ferme-' || i FROM generate_series(1, #{tenants}) AS i
    SQL

    # Des parcelles réparties sur une grille : chaque ferme a les siennes, et
    # elles se chevauchent d'une ferme à l'autre — le cas qui compte, puisque
    # c'est là qu'un index spatial sans `tenant_id` ramènerait tout le monde.
    owner.execute(<<~SQL)
      INSERT INTO ekylibre.products
        (tenant_id, type, name, number, variant_id, nature_id, category_id, variety, initial_shape, created_at, updated_at)
      SELECT t.id, 'Plant', 'parcelle ' || i, 'P' || i, 1, 1, 1, 'plant',
             postgis.ST_Multi(postgis.ST_MakeEnvelope(
               (i % 100) * 0.01, 44 + (i % 100) * 0.01,
               (i % 100) * 0.01 + 0.008, 44 + (i % 100) * 0.01 + 0.008, 4326)),
             now() - (i || ' days')::interval, now()
        FROM ekylibre.tenants t, generate_series(1, #{rows}) AS i
    SQL

    owner.execute(<<~SQL)
      INSERT INTO ekylibre.interventions
        (tenant_id, procedure_name, state, nature, started_at, stopped_at, working_duration, whole_duration, created_at, updated_at)
      SELECT t.id, 'sowing', 'done', 'record', now() - (i || ' days')::interval, now(), 3600, 3600,
             now() - (i || ' days')::interval, now()
        FROM ekylibre.tenants t, generate_series(1, #{rows / 2}) AS i
    SQL

    owner.execute('ANALYZE ekylibre.products')
    owner.execute('ANALYZE ekylibre.interventions')
  end

  def tenant_sample
    owner.select_value('SELECT id FROM ekylibre.tenants ORDER BY slug LIMIT 1')
  end

  # Les plans sont lus avec le rôle applicatif : c'est sous la politique qu'ils
  # comptent, pas au-dessus.
  def explain(tenant_id, sql)
    application.transaction do
      application.execute("SET LOCAL app.tenant_id = #{application.quote(tenant_id)}")
      application.select_values("EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) #{sql}").join("\n")
    end
  end

  def measurements(tenant_id)
    {
      'liste des parcelles de la ferme' =>
        'SELECT count(*) FROM ekylibre.products',
      'parcelles intersectant une emprise' =>
        "SELECT count(*) FROM ekylibre.products WHERE initial_shape && postgis.ST_MakeEnvelope(0.10, 44.10, 0.13, 44.13, 4326)",
      'interventions des trente derniers jours' =>
        "SELECT count(*) FROM ekylibre.interventions WHERE started_at > now() - interval '30 days'"
    }.transform_values { |sql| explain(tenant_id, sql) }
  end

  def sizes
    owner.select_rows(<<~SQL)
      SELECT relname, pg_size_pretty(pg_total_relation_size(c.oid)), reltuples::bigint
        FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'ekylibre' AND relname IN ('products', 'interventions')
       ORDER BY relname
    SQL
  end
end

namespace :monoschema do
  desc 'Peuple la sonde et mesure les plans à l’échelle (TENANTS=, ROWS=)'
  task scale: :environment do
    tenants = Integer(ENV.fetch('TENANTS', '200'))
    rows = Integer(ENV.fetch('ROWS', '2000'))

    started = Time.current
    MonoschemaScale.populate(tenants, rows)
    puts "  #{tenants} fermes peuplées en #{(Time.current - started).round(1)} s"
    MonoschemaScale.sizes.each { |name, size, count| puts format('  %<name>-14s %<count>10d lignes  %<size>s', name: name, count: count, size: size) }

    tenant = MonoschemaScale.tenant_sample
    MonoschemaScale.measurements(tenant).each do |label, plan|
      access = plan.scan(/(?:Seq Scan on|Index Scan using|Index Only Scan using|Bitmap Index Scan on|Bitmap Heap Scan on) (\S+)/).flatten.uniq
      time = plan[/Execution Time: ([\d.]+) ms/, 1]
      scanned = plan.scan(/actual rows=(\d+)/).flatten.map(&:to_i).max
      buffers = plan[/Buffers: shared hit=(\d+)(?: read=(\d+))?/, 1]
      puts "\n  #{label}"
      puts "    chemin : #{access.join(' + ')}"
      puts "    lignes parcourues : #{scanned}   blocs lus : #{buffers}   temps : #{time} ms"
    end
  end
end
