require 'test_helper'
module Backend
  class ProductNatureVariantComponentsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions autocomplete: { column: :name, q: 'Sab' }
  end
end
