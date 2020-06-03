require 'test_helper'

module PanierLocal
  class BaseTest < Ekylibre::Testing::ApplicationTestCase
    class MyExchanger < PanierLocal::Base

      def provider_name
        :my_provider
      end
    end

    setup do
      @import = Import.create!(nature: :panier_local_sales)
      @e = MyExchanger.new('', nil, import_id: @import.id)
    end

    test 'unwrap_one' do
      assert_equal 1, @e.unwrap_one('one') { [1] }
      assert_nil @e.unwrap_one('nil') { [] }
      assert_raises(PanierLocal::Base::UniqueResultExpectedError) do
        @e.unwrap_one('multiple') { [1, 2] }
      end

      assert_raises(PanierLocal::Base::UniqueResultExpectedError) do
        @e.unwrap_one('strict', exact: true) { [] }
      end
    end

    test 'entity provider find' do
      assert_nil @e.find_entity_by_provider("42")
      e = create :entity, provider: { vendor: :panier_local, name: :myprovider, id: 42, data: { entity_code: '42' } }
      assert_equal e, @e.find_entity_by_provider("42")
    end

    test 'client is searched by account if provider fails' do
      a = create :account
      e = create :entity, client: true, client_account: a

      stub_many @e, find_entity_by_provider: nil, find_account_by_provider: a do
        e2 = @e.find_or_create_entity("", "", "42")
        assert e2
        assert_equal e, e2
      end
    end

    test 'Entity is created if provider find by_account fails' do
      e = @e.find_or_create_entity('toto', '411058', "42")
      assert e
      assert e.is_provided_by?(vendor: 'panier_local', name: 'my_provider')
      assert e.client_account.is_provided_by?(vendor: 'panier_local', name: 'my_provider')
    end

    test 'account provider find uses provider_data' do
      assert_nil @e.find_account_by_provider('706')
      a = create :account, number: '7068', provider: { vendor: :panier_local, name: :my_provider, id: 42, data: { account_number: '706' } }
      assert_equal a, @e.find_account_by_provider('706')
    end
  end
end
