require 'test_helper'
module Backend
  class ShipmentsControllerTest < ActionController::TestCase
    test_restfully_all_actions ship: { mode: :multi_touch, fixture: { first: 3, second: 4 } },
                               check: :touch,
                               order: :touch,
                               prepare: :touch,
                               cancel: :touch,
                               give: :touch
  end
end
