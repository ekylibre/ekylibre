# encoding: UTF-8
require 'test_helper'

class Ekylibre::TenantTest < ActiveSupport::TestCase

  def test_tenant_creation
    Ekylibre::Tenant.create("foobar")
    assert Ekylibre::Tenant.exist?("foobar")
    Ekylibre::Tenant.switch("foobar")
    Ekylibre::Tenant.drop("foobar")
    assert !Ekylibre::Tenant.exist?("foobar")
  end

end
