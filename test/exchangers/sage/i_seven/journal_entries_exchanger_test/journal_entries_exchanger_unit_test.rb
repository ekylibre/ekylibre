require 'test_helper'

module Sage
  module ISeven
    module JournalEntriesExchangerTest
      class JournalEntriesExchangerUnitTest < Ekylibre::Testing::ApplicationTestCase
        setup do
          @import = Import.create!(nature: :sage_i_seven_journal_entries)

          Preference.set!(:account_number_digits, 8, :integer)

          @e = Sage::ISeven::JournalEntriesExchanger.new('', nil, import_id: @import.id)
          @e.instance_variable_set('@file_info', {version_information: '42'}.to_struct)
        end
        
        test "account_radix methods returns the preference value" do
            Preference.set!('client_account_radix', '88888', :string)
            assert_equal '88888', @e.send(:client_account_radix)

            Preference.set!('supplier_account_radix', '88848', :string)
            assert_equal '88848', @e.send(:supplier_account_radix)
        end

        test "account_radix methods returns the default value if the preference is empty string" do
          Preference.set!('client_account_radix', "", :string)
          assert_equal '411', @e.send(:client_account_radix)

          Preference.set!('supplier_account_radix', "", :string)
          assert_equal '401', @e.send(:supplier_account_radix)
        end

        test 'create_account general is general' do
          account = @e.send(:create_account, '70455555', '70455555', 'general_account')
          assert account.general?
        end

        test 'create_account with client_prefix is auxiliary' do
          stub_many @e, supplier_account_radix: '401', client_account_radix: '411' do
            account = @e.send(:create_account, "411432", "41143200", "qlikzudgqlzkjydg")
            
            assert account.auxiliary?
          end
        end

        test 'create_account with supplier_prefix is auxiliary' do
          stub_many @e, supplier_account_radix: '401', client_account_radix: '411' do
            account = @e.send(:create_account, "401432", "40143200", "qlikzudgqlzkjydg")
            
            assert account.auxiliary?
          end
        end

        test 'create_entity' do
          account = create(:account, :client)
          sage_account_number = '111111111'
          period_started_on = Date.new(2020, 3, 3)
          entity = @e.send(:create_entity, period_started_on, account, sage_account_number)
          
          assert  entity
          assert entity.client
          assert_equal account.id, entity.client_account_id
          assert_equal period_started_on, entity.first_met_at
          assert_equal entity, @e.send(:find_entity_by_provider, sage_account_number)
        end
      end
    end
  end
end
