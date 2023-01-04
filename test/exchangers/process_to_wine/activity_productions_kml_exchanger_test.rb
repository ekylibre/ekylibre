require 'test_helper'

module ProcessToWine
  class ActivityProductionsKmlExchangerTest < ActiveExchanger::TestCase
    setup do
      # We want to keep tracking of import resource
      I18n.locale = :fra
      @year = Time.zone.now.year
      @import = Import.create!(nature: :process_to_wine_activity_productions_kml, creator: User.first)
    end

    test 'import' do
      result = ProcessToWine::ActivityProductionsKmlExchanger.build(fixture_files_path.join('imports', 'process_to_wine', 'productions.kml'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
