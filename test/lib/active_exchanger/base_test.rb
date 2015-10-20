require 'test_helper'

class ActiveExchanger::BaseTest < ActiveSupport::TestCase
  FIRST_RUN_V1 = fixture_files_path.join('first_run', 'v1')

  # TODO: fix use of manifest.yml which used for fixtures...
  IMPORTS = {
    ekylibre_settings: FIRST_RUN_V1.join('manifest.yml'),
    ekylibre_visuals: fixture_files_path.join('sample_image.png')
  }

  setup do
    # Ekylibre::Tenant.create(:sekindovall)
    Ekylibre::Tenant.switch!(:sekindovall)
  end

  teardown do
    # Ekylibre::Tenant.drop(:sekindovall)
    Ekylibre::Tenant.switch!(:test)
  end

  test 'import of a ekylibre_settings file' do
    ActiveExchanger::Base.import(:ekylibre_settings, FIRST_RUN_V1.join('manifest.yml'))
  end

  test 'import of a ekylibre_visuals file' do
    ActiveExchanger::Base.import(:ekylibre_visuals, fixture_files_path.join('sample_image.png'))
  end

  test 'import of a legrain_epicea_accounts file' do
    ActiveExchanger::Base.import(:legrain_epicea_accounts, FIRST_RUN_V1.join('epicea', 'PlanComptable.Txt'))
  end

  test 'import of a legrain_epicea_journals file' do
    ActiveExchanger::Base.import(:legrain_epicea_journals, FIRST_RUN_V1.join('epicea', 'ExportationDesEcritures.Txt'))
  end

  test 'import of a ekylibre_cap_land_parcel_clusters_json file' do
    ActiveExchanger::Base.import(:ekylibre_cap_land_parcel_clusters_json, fixture_files_path.join('ekylibre_cap_land_parcel_clusters.json'))
  end

  test 'import of a ekylibre_cap_land_parcels_json file' do
    ActiveExchanger::Base.import(:ekylibre_cap_land_parcels_json, fixture_files_path.join('ekylibre_cap_land_parcels.json'))
  end

  test 'import of a ekylibre_cultivable_zones_json file' do
    ActiveExchanger::Base.import(:ekylibre_cultivable_zones_json, fixture_files_path.join('ekylibre_cultivable_zones.json'))
  end

  test 'import of a ekylibre_buildings_json file' do
    ActiveExchanger::Base.import(:ekylibre_buildings_json, fixture_files_path.join('ekylibre_buildings.json'))
  end

  # test 'import of a ekylibre_storages_json file' do
  #   ActiveExchanger::Base.import(:ekylibre_storages_json, fixture_files_path.join('ekylibre_storages.json'))
  # end
end
