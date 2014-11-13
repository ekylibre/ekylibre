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

  #~ for importer, path in IMPORTS
    #~ test "import of a #{importer} file" do
      #~ Exchanges.import(importer, path)
    #~ end
  #~ end

  test "import of a ekylibre_erp_settings file" do
    Exchanges.import(:ekylibre_erp_settings, FIRST_RUN.join("manifest"))
  end

  test "import of a ekylibre_erp_visuals file" do
    Exchanges.import(:ekylibre_erp_visuals, FIRST_RUN.dirname.join("sample_image.png"))
  end

  test "import of a legrain_epicea_accounts file" do
    Exchanges.import(:legrain_epicea_accounts, FIRST_RUN.join("epicea","PlanComptable.Txt"))
  end

  test "import of a legrain_epicea_journals file" do
    Exchanges.import(:legrain_epicea_accounts, FIRST_RUN.join("epicea","ExportationDesEcritures.Txt"))
  end
end
