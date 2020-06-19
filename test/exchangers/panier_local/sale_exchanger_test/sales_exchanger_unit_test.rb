require 'test_helper'

module PanierLocal
  module SaleExchangerUnitTest
    class SalesExchangerTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        Preference.set!(:country, 'fr')

        @import = Import.create!(nature: :panier_local_sales)
        @e = PanierLocal::SalesExchanger.new('', ActiveExchanger::Supervisor.new, import_id: @import.id)
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
        assert_equal s, @e.find_or_create_sale([], s.nature, reference_number: '42').get
      end

      test 'the check method returns false when no responsible is linked' do
        create :financial_year, year: 2020

        stub_many @e, responsible: nil, open_and_decode_file: [[{ invoiced_at: DateTime.parse("2020-05-05T00:00:00Z") }.to_struct], []] do
          assert_not @e.check
        end

        stub_many @e, responsible: nil, open_and_decode_file: [[{ invoiced_at: DateTime.parse("2020-05-05T00:00:00Z") }.to_struct], []] do
          stub_many @e.import_resource, creator: nil do
            assert_not @e.check
          end
        end
      end

      test 'the responsible is the creator of the import' do
        user = create :user
        stub_many @e.import_resource, creator: user do
          assert_equal user, @e.responsible
        end
      end

      test "sale is created if nout found by provider" do
        create :financial_year, year: 2020
        sale_nature = create :sale_nature

        info = [
          { sale_item_amount: 480, account_number: "4110085", entity_name: 'name', entity_code: 'code' }.to_struct,
          { sale_item_amount: 400, sale_description: '', account_number: "7528215", invoiced_at: DateTime.parse("2020-05-05T00:00:00Z"), sale_item_direction: 'C' }.to_struct,
          { sale_item_amount: 80, account_number: "4458558", invoiced_at: DateTime.parse("2020-05-05T00:00:00Z"), vat_percentage: 20 }.to_struct
        ]

        stub_many @e, find_sale_by_provider: nil do
          s = @e.find_or_create_sale(info, sale_nature, reference_number: 42)

          assert s.is_some?
          assert_equal 480, s.get.amount
        end
      end

      test 'exchanger stops if missing VAT information' do
        info = [
          { sale_item_amount: 480, sale_reference_number: '42', account_number: "4110085", entity_name: 'name', entity_code: 'code' }.to_struct,
          { sale_item_amount: 400, sale_reference_number: '42', account_number: "7555" }.to_struct,
        ]

        assert_raise PanierLocal::Base::UniqueResultExpectedError do
          @e.create_sale(info, create(:sale_nature), reference_number: '42')
        end
      end

      test 'sales with only one client line and amount 0 should be ignored' do
        create :financial_year, year: 2020
        sale_nature = create :sale_nature

        info = [{ sale_item_amount: 0, account_number: '41100001' }.to_struct]

        assert @e.create_sale(info, sale_nature, reference_number: '42').is_none?
      end
    end
  end
end