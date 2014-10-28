# encoding: UTF-8
require 'test_helper'

class ExchangesTest < ActiveSupport::TestCase

  FIRST_RUN = Rails.root.join("test", "fixtures", "files", "first_run")

  # TODO fix use of manifest.yml which used for fixtures...
  IMPORTS = {
    ekylibre_erp_settings: FIRST_RUN.join("manifest"),
    ekylibre_erp_visuals: FIRST_RUN.dirname.join("sample_image.png")
  }

  setup do
    Ekylibre::Tenant.create(:sekindovall)
    Ekylibre::Tenant.switch(:sekindovall)
  end

  teardown do
    Ekylibre::Tenant.drop(:sekindovall)
  end

  for importer, path in IMPORTS
    test "import of a #{importer} file" do
      Exchanges.import(importer, path)
    end
  end

end
