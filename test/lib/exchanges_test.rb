# encoding: UTF-8
require 'test_helper'

class ExchangesTest < ActiveSupport::TestCase

  setup do
    Ekylibre::Tenant.create(:sekindovall)
    Ekylibre::Tenant.switch(:sekindovall)
  end

  teardown do
    Ekylibre::Tenant.drop(:sekindovall)
  end

  test "Ekylibre ERP importers" do
    dir = Rails.root.join("test", "fixtures", "files", "first_run")

    Exchanges.import(:ekylibre_erp_settings, dir.join("manifest"))
  end

end
