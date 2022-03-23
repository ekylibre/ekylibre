require 'test_helper'

module Ekylibre
  class WorkerTimeLogsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::WorkerTimeLogsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'worker_time_logs.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
