require 'test_helper'

module Ekylibre
  class TenantTest < ActiveSupport::TestCase
    def test_tenant_creation
      Ekylibre::Tenant.create('foobar')
      assert Ekylibre::Tenant.exist?('foobar')
      Ekylibre::Tenant.switch!('foobar')
      assert_equal 'foobar', Ekylibre::Tenant.current
      Ekylibre::Tenant.create('foobarbaz')
      Ekylibre::Tenant.switch('foobarbaz') do
        assert_equal 'foobarbaz', Ekylibre::Tenant.current
      end
      assert_equal 'foobar', Ekylibre::Tenant.current
      Ekylibre::Tenant.drop('foobarbaz')
      Ekylibre::Tenant.drop('foobar')
      Ekylibre::Tenant.switch!('test')
      assert !Ekylibre::Tenant.exist?('foobar')
      assert !Ekylibre::Tenant.exist?('foobarbaz')
    end
  end
end
