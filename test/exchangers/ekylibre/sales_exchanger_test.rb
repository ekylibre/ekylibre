require 'test_helper'

module Ekylibre
  class SalesExchangerTest < ActiveExchanger::TestCase

    # FIX ME "undefined method `[]' for nil:NilClass", #<NoMethodError: undefined method `[]' for nil:NilClass>
    # setup do
    # We want to keep tracking of import resource
    #  ::I18n.locale = :fra
    #  @import = Import.create!(nature: :ekylibre_sales, creator: User.first)
    #  @second_import = Import.create!(nature: :ekylibre_sales, creator: User.first)
    # end

    # test 'import' do
    # result = Ekylibre::SalesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'sales.csv'), options: { import_id: @import.id }).run
    # assert result.success?, [result.message, result.exception]
    # end
  end
end
