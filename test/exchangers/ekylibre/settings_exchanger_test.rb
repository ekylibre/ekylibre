require 'test_helper'

module Ekylibre
  class SettingsExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:ekylibre_settings, fixture_files_path.join('imports', 'ekylibre_settings.yml'))
    end
  end
end
