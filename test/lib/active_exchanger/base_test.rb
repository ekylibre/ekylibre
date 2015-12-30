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

  Nomen::ExchangeNature.find_each do |item|
    path = fixture_files_path.join('imports', "#{item.name}.*")
    list = Dir.glob(path)
    if list.any?
      list.each do |file|
        test "#{item.name} import with #{File.basename(file)}" do
          ActiveExchanger::Base.import(item.name, file)
        end
      end
    else
      puts "Cannot test exchanger #{item.name.to_s.yellow} import. No file given."
    end
  end
end
