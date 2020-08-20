# frozen_string_literal: true

require 'test_helper'

class ActiveSupportDurationTest < Ekylibre::Testing::ApplicationTestCase
  test "iso8601 duration should be correctly parsed" do
    assert_equal 8752, ActiveSupport::Duration.parse("PT2H25M52S").to_i
  end
end