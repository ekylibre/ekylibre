require 'test_helper'

module Ekylibre
  class WorkersExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:ekylibre_workers, fixture_files_path.join('imports', 'ekylibre_workers.csv'))
    end
  end
end
