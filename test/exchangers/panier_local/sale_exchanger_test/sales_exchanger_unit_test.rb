require 'test_helper'

module PanierLocal
  module SaleExchangerUnitTest
    class SalesExchangerTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @import = Import.create!(nature: :panier_local_sales)
        @e = PanierLocal::SalesExchanger.new('', nil, import_id: @import.id)
      end

      test 'journal provider find' do
        assert_nil @e.find_journal_by_provider
        j = create :journal, provider: { vendor: :panier_local, name: :sales, id: 42 }
        assert_equal j, @e.find_journal_by_provider
      end

      test 'find_or_create_journal creates it if provider does not find it' do
        stub_many @e, find_journal_by_provider: nil do
          j = @e.find_or_create_journal
          assert j
          assert j.is_provided_by?(vendor: 'panier_local', name: 'sales')
        end
      end

      test 'catalog provider find' do
        assert_nil @e.find_catalog_by_provider
        c = create :catalog, provider: { vendor: :panier_local, name: :sales, id: 42 }
        assert_equal c, @e.find_catalog_by_provider
      end

      test 'find_or_create_catalog creates it if provider does not find it' do
        stub_many @e, find_catalog_by_provider: nil do
          c = @e.find_or_create_catalog
          assert c
          assert c.is_provided_by?(vendor: 'panier_local', name: 'sales')
        end
      end

      test 'sale_nature provider find' do
        assert_nil @e.find_sale_nature_by_provider
        sn = create :sale_nature, provider: { vendor: :panier_local, name: :sales, id: 42 }
        assert_equal sn, @e.find_sale_nature_by_provider
      end

      test 'get sale_nature by name if provider does not find id' do
        sn = create :sale_nature, name: I18n.t('exchanger.panier_local.sales.sale_nature_name')

        stub_many @e, find_sale_nature_by_provider: nil do
          assert_equal sn, @e.find_or_create_sale_nature
        end
      end

      test 'sale_nature created if absent' do
        stub_many @e, find_sale_nature_by_provider: nil do
          sn = @e.find_or_create_sale_nature

          assert sn
          assert sn.is_provided_by?(vendor: 'panier_local', name: 'sales')
        end
      end

      test 'create_pretax_amount computation' do
        assert_equal 42, @e.create_pretax_amount({ sale_item_direction: 'C', sale_item_amount: 42 }.to_struct)
        assert_equal -42, @e.create_pretax_amount({ sale_item_direction: 'D', sale_item_amount: 42 }.to_struct)
      end

      test 'find_or_create_product_account find by number' do
        create :account, number: '706'

        stub_many @e, find_account_by_provider: nil do
          a = @e.find_or_create_product_account('706')
          assert a
          assert_not a.is_provided_by?(vendor: 'panier_local', name: 'sales')
        end
      end

      test 'find_or_create_product_account creates if not found' do
        stub_many @e, find_account_by_provider: nil do
          a = @e.find_or_create_product_account('706')
          assert a
          assert a.is_provided_by?(vendor: 'panier_local', name: 'sales')
        end
      end

      test 'product_nature_variant provider find' do
        assert_nil @e.find_variant_by_provider('706')
        pnv = create :product_nature_variant, provider: { vendor: :panier_local, name: :sales, id: 42, data: { account_number: '706' } }
        assert_equal pnv.id, @e.find_variant_by_provider('706').id
      end

      test 'tax provider find' do
        assert_nil @e.find_tax_by_provider(10.6, '706')
        t = create :tax, provider: { vendor: :panier_local, name: :sales, id: 42, data: { account_number: '706', vat_percentage: 10.6 } }
        assert_equal t, @e.find_tax_by_provider(10.6, '706')
        assert_equal t, @e.find_or_create_tax({ vat_percentage: 10.6, account_number: '706' }.to_struct)
      end

      test 'tax is found by account if provider returns nil' do
        a = create :account
        t = create :tax, amount: 10.6, collect_account: a
        stub_many @e, find_tax_by_provider: nil, find_account_by_provider: a do
          assert_equal t, @e.find_or_create_tax({ vat_percentage: 10.6, account_number: '706' }.to_struct)
        end
      end

      test 'tax is created if provider and by_account fails' do
        t = create :tax

        stub_many @e, find_tax_by_provider: nil do
          stub_many Tax, find_by: nil, find_on: t do
            t2 = @e.find_or_create_tax({ invoiced_at: DateTime.parse('2019-01-01T00:00:00Z'), vat_percentage: 10.6, account_number: '706' }.to_struct)
            assert_equal t, t2
            assert t2.is_provided_by?(vendor: 'panier_local', name: 'sales')
            assert t2.collect_account.is_provided_by?(vendor: 'panier_local', name: 'sales')
          end
        end
      end

      test 'sale provider find' do
        assert_nil @e.find_sale_by_provider("42")
        s = create :sale, provider: { vendor: :panier_local, name: :sales, id: 42, data: { sale_reference_number: '42' } }
        assert_equal s, @e.find_sale_by_provider("42")
      end

      test 'sale is not created if found by provider' do
        s = create :sale, provider: { vendor: :panier_local, name: :sales, id: 42, data: { sale_reference_number: '42' } }
        assert_equal s, @e.find_or_create_sale([{ sale_reference_number: "42" }.to_struct], s.nature)
      end

    end
  end
end