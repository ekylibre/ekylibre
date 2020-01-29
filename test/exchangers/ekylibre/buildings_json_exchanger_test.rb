require 'test_helper'

module Ekylibre
  class BuildingsJsonExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::BuildingsJsonExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'buildings_json.json')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
