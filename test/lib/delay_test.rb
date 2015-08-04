# encoding: UTF-8
require 'test_helper'

class DelayTest < ActiveSupport::TestCase
  def test_delay
    Delay.new('')
    Delay.new
    Delay.new('1 day')
    Delay.new('1 day, eom, 3 years')
    Delay.new('1 day, eom, 3 years ago')
    delay = Delay.new('3 month')
    date = Date.civil(2000, 1, 23)
    assert_equal Date.civil(2000, 4, 23), delay.compute(date)
    date = Date.civil(2003, 2, 28)
    assert_equal Date.civil(2003, 5, 28), delay.compute(date)
    date = Date.civil(2002, 11, 30)
    assert_equal Date.civil(2003, 2, 28), delay.compute(date)
  end
end
