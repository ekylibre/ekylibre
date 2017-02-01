require 'test_helper'
module Backend
  class ProductNatureVariantComponentsControllerTest < ActionController::TestCase
    test_restfully_all_actions autocomplete: { column: :name, q: 'Sab' }
  end
end
