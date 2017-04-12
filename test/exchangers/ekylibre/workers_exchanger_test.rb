require 'test_helper'

module Ekylibre
  class WorkersExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::WorkersExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'workers.csv'))
    end
  end
end
