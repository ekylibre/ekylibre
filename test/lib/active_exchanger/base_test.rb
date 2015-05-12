require 'test_helper'

class ActiveExchanger::BaseTest < ActiveSupport::TestCase

  FIRST_RUN = Rails.root.join("test", "fixtures", "files", "first_run")

  # TODO fix use of manifest.yml which used for fixtures...
  IMPORTS = {
    ekylibre_settings: FIRST_RUN.join("manifest"),
    ekylibre_visuals: FIRST_RUN.dirname.join("sample_image.png")
  }

  setup do
    # Ekylibre::Tenant.create(:sekindovall)
    Ekylibre::Tenant.switch!(:sekindovall)
  end

  teardown do
    # Ekylibre::Tenant.drop(:sekindovall)
    Ekylibre::Tenant.switch!(:test)
  end

  test "import of a ekylibre_settings file" do
    ActiveExchanger::Base.import(:ekylibre_settings, FIRST_RUN.join("manifest"))
  end

  test "import of a ekylibre_visuals file" do
    ActiveExchanger::Base.import(:ekylibre_visuals, FIRST_RUN.dirname.join("sample_image.png"))
  end

  test "import of a legrain_epicea_accounts file" do
    ActiveExchanger::Base.import(:legrain_epicea_accounts, FIRST_RUN.join("epicea", "PlanComptable.Txt"))
  end

  test "import of a legrain_epicea_journals file" do
    ActiveExchanger::Base.import(:legrain_epicea_journals, FIRST_RUN.join("epicea", "ExportationDesEcritures.Txt"))
  end
end
