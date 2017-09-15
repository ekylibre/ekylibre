require 'test_helper'

module Ekylibre
  class SettingsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::SettingsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'settings.yml'))
    end
  end
end
