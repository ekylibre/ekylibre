# frozen_string_literal: true

require 'test_helper'
require 'securerandom'

class EntityEinvoicingTest < ActiveSupport::TestCase
  test 'lists every missing mention for a bare organization' do
    org = build_org
    assert_equal %i[siret address banking].sort, org.einvoicing_missing_mentions.sort
    refute org.einvoicing_operational
  end

  test 'is operational once SIRET, address and banking are present' do
    org = build_org(siret_number: '12369874500015', iban: 'FR7630001007941234567890185')
    org.stub(:default_mail_address, Object.new) do
      assert_empty org.einvoicing_missing_mentions
      assert org.einvoicing_operational
    end
  end

  test 'reports only the actual gap (missing banking)' do
    org = build_org(siret_number: '12369874500015')
    org.stub(:default_mail_address, Object.new) do
      assert_equal [:banking], org.einvoicing_missing_mentions
    end
  end

  test 'does not apply to non-organizations' do
    contact = build_org(nature: 'contact', first_name: 'John')
    assert_nil contact.einvoicing_operational
    assert_empty contact.einvoicing_missing_mentions
  end

  private

    def build_org(attrs = {})
      Entity.create!({
        nature: 'organization', country: 'fr', last_name: "Co-#{SecureRandom.hex(4)}",
        currency: 'EUR', language: 'fra'
      }.merge(attrs))
    end
end
