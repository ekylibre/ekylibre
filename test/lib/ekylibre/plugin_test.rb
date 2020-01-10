require 'test_helper'

module Ekylibre
  class PluginTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    test 'load fake plugin' do
      Ekylibre::Plugin.load_plugin(fixture_files_path.join('plugins', 'dummy'))
    end
  end
end
