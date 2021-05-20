require 'test_helper'
module Backend
  class CropGroupsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[kujaku_options unroll_list duplicate]

    setup do
      @crop_group = create(:crop_group, :with_items, :with_labelings)
    end

    attr_reader :crop_group

    test 'duplicate create a new crop_group' do

      post :duplicate, params: { id: crop_group.id }
      duplicate_crop_group = CropGroup.order(created_at: :desc).first

      assert_equal crop_group.name + ' (1)', duplicate_crop_group.name
      assert_equal crop_group.target, duplicate_crop_group.target
      assert_equal crop_group.labels.pluck(:id), duplicate_crop_group.labels.pluck(:id)

      assert_equal crop_group.items.count, duplicate_crop_group.items.count
      assert_equal crop_group.labellings.count, duplicate_crop_group.labellings.count

      assert_equal crop_group.items.pluck(:crop_id).sort, duplicate_crop_group.items.pluck(:crop_id).sort
      assert_equal crop_group.labellings.pluck(:label_id).sort, duplicate_crop_group.labellings.pluck(:label_id).sort
    end
  end
end
