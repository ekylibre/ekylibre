require 'test_helper'

module Backend
  class CatalogItemsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { catalog_id: 1 }, create: { catalog_id: 1 }, other_attributes: [:variant_id], stop: :touch
  end
end
