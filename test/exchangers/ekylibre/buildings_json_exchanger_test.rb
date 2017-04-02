require 'test_helper'

module Ekylibre
  class BuildingsJsonExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::BuildingsJsonExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'buildings_json.json'))
    end
  end
end
