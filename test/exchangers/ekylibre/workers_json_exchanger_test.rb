require 'test_helper'

module Ekylibre
  class WorkersExchangerJsonTest < ActiveExchanger::TestCase
    test 'import' do
      worker_count = Worker.count
      result = Ekylibre::WorkersJsonExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'ekylibre_workers.json')).run
      assert result.success?, [result.message, result.exception]
      assert_equal worker_count + 2, Worker.count, 'It creates the right number of worker'
    end
  end
end
