require 'test_helper'

module Ekylibre
  class SettingsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::SettingsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'settings.yml')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
