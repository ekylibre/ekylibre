require 'test_helper'

module Ekylibre
  class TenantTest < ActiveSupport::TestCase
    test 'tenant creation and destruction' do
      Ekylibre::Tenant.create('foobar')
      assert Ekylibre::Tenant.exist?('foobar')
      Ekylibre::Tenant.switch!('foobar')
      assert_equal 'foobar', Ekylibre::Tenant.current
      Ekylibre::Tenant.switch('test') do
        assert_equal 'test', Ekylibre::Tenant.current
      end
      assert_equal 'foobar', Ekylibre::Tenant.current
      Ekylibre::Tenant.drop('foobar')
      Ekylibre::Tenant.switch!('test')
      assert !Ekylibre::Tenant.exist?('foobar')
      assert_equal 'test', Ekylibre::Tenant.current
    end
  end
end
