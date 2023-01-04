require 'test_helper'

module Ekylibre
  class RidesExchangerTest < ActiveExchanger::TestCase
    setup do
      # We want to keep tracking of import resource
      @import = Import.create!(nature: :ekylibre_rides, creator: User.first)
    end

    test 'import' do
      result = Ekylibre::RidesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'rides.zip'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
