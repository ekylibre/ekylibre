require 'test_helper'

module Ekylibre
  # Garde-fou CI pour la synchronisation `demo-data/demo/` →
  # `db/first_runs/demo/`. Ne clone pas demo-data en CI (le repo est public
  # mais externe) : vérifie juste que `.source_sha` est présent et bien formé.
  # Si un dev modifie manuellement un fichier sous db/first_runs/demo/ sans
  # repasser par bin/sync_demo_data, ce test ne détecte pas la dérive mais
  # il force à expliciter la provenance (sha ou "unknown").
  class DemoSourceSyncTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    DEMO_DIR = Rails.root.join('db', 'first_runs', 'demo').freeze
    SOURCE_SHA_FILE = DEMO_DIR.join('.source_sha').freeze
    SHA_PATTERN = /\A([0-9a-f]{7,40}(-dirty)?|unknown)\n?\z/

    # `db/first_runs/demo` is gitignored (see .gitignore line 27) : CI nodes
    # that didn't run bin/sync_demo_data won't have it. We only enforce the
    # invariants on hosts that opted to materialize the folder.

    test 'when materialized, db/first_runs/demo carries a valid .source_sha marker' do
      skip "demo folder absent, run bin/sync_demo_data to populate it" unless DEMO_DIR.directory?
      assert SOURCE_SHA_FILE.file?,
             "#{SOURCE_SHA_FILE} is missing — re-run `bin/sync_demo_data`"
      marker = SOURCE_SHA_FILE.read.strip
      assert_match SHA_PATTERN, marker,
                   "Unexpected .source_sha content: #{marker.inspect}"
    end

    test 'when materialized, demo manifest.yml targets demo.ekylibre-dev.com and declares EX2026' do
      skip "demo folder absent, run bin/sync_demo_data to populate it" unless DEMO_DIR.join('manifest.yml').file?
      manifest = YAML.load_file(DEMO_DIR.join('manifest.yml'))
      assert_equal 'demo.ekylibre-dev.com', manifest['host']
      assert manifest.dig('financial_years', 'EX2026'),
             'EX2026 missing from demo manifest'
    end
  end
end
