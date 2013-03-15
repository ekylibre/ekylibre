require 'test_helper'

class <%= class_name -%>Test < ActiveSupport::TestCase

  test "presence of fixtures" do
    assert_equals 2, <%= class_name -%>.count
  end

end
