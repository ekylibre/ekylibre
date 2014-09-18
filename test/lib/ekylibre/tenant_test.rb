# encoding: UTF-8
require 'test_helper'

class Ekylibre::TenantTest < ActiveSupport::TestCase

  def test_tenant_creation
    Ekylibre::Tenant.create("test")
    assert Ekylibre::Tenant.exist?("test")
    Ekylibre::Tenant.switch("test")
    Ekylibre::Tenant.drop("test")
    assert !Ekylibre::Tenant.exist?("test")
  end

end
