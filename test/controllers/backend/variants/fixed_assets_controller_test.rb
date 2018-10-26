require 'test_helper'
module Backend
  module Variants
    class FixedAssetsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :fixed_assets_datas
    end
  end
end
