require 'test_helper'

class Backend::CatalogItemsControllerTest < ActionController::TestCase
  test_restfully_all_actions other_attributes: [:variant_id], stop: :touch
end
