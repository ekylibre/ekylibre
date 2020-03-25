require 'test_helper'

class HasIntervalTest < Ekylibre::Testing::ApplicationTestCase
  class Dummy
    include ActiveModel::Model
    include HasInterval

    attr_accessor :intercepted

    has_interval :delay

    def []=(_key, value)
      @intercepted = value
    end

    def [](_key)
      @intercepted
    end
  end

  setup do
    @dummy = Dummy.new
  end

  test "setter works" do
    @dummy.delay = "PT3H"
    assert_equal "PT3H", @dummy.intercepted

    @dummy.delay = ActiveSupport::Duration.parse("PT3H")
    assert_equal "PT3H", @dummy.intercepted

    @dummy.delay = ""
    assert_nil @dummy.intercepted
  end

end