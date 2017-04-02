require 'test_helper'

module Ekylibre
  class ActivitiesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::ActivitiesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'activities.csv'))
    end
  end
end
