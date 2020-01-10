require 'test_helper'
module Backend
  module Variants
    class FixedAssetsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :fixed_assets_datas
    end
  end
end
