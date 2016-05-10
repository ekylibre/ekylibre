module Ekylibre
  class BackupExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      ActiveExchanger::Base.import(:ekylibre_backup, fixture_files_path.join('imports', 'ekylibre_backup.zip'))
    end
  end
end
