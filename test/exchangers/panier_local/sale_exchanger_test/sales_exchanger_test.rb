require 'test_helper'

module PanierLocal
  module SaleExchangerTest
    class SalesExchangerTest < ActiveExchanger::TestCase
      setup do
        # We wan't to keep tracking of import resource
        @import = Import.create!(nature: :panier_local_sales, creator: User.first)

        I18n.locale = :fra
      end

      test 'import' do
        result = PanierLocal::SalesExchanger.build(fixture_files_path.join('imports', 'panier_local', 'panier_local_sales.csv'), options: { import_id: @import.id }).run
        assert result.success?, -> { [result.message, result.exception&.backtrace&.first] }

        sales = Sale.of_provider(:panier_local, :sales, @import.id)
        assert_equal 3, sales.count

        asserts = [
          # reference, amount, item_count, item_quantities
          ['00706', 2681.64, 1, [63]],
          ['00707', 164.99, 1, [1]],
          ['875', 6210.40, 2, [175, 1]]
        ]

        asserts.each do |(reference, amount, item_count, quantities)|
          sale = sales.of_provider_data(:sale_reference_number, reference).first
          assert sale
          assert_equal amount, sale.amount
          assert_equal item_count, sale.items.count
          assert quantities.all? { |q| sale.items.any? { |i| i.quantity == q } }
        end
      end

      teardown do
        @import.destroy!
      end
    end
  end
end