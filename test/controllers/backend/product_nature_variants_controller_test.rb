require 'test_helper'

class Backend::ProductNatureVariantsControllerTest < ActionController::TestCase

  test_restfully_all_actions last_purchase_item: :show, quantifiers: {format: :json, mode: :show}

end

