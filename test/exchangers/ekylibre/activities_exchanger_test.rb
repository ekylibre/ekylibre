require 'test_helper'

module Ekylibre
  class ActivitiesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::ActivitiesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'activities.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
