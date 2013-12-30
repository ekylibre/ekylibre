# encoding: UTF-8
require 'test_helper'

class MeasureTest < ActiveSupport::TestCase

  def test_instanciation
    assert_nothing_raised do
      Measure.new(55.23, "kilogram")
    end
    assert_nothing_raised do
      Measure.new(55.23, :kilogram)
    end
    assert_nothing_raised do
      Measure.new("55.23 kilogram")
    end
    assert_nothing_raised do
      Measure.new("55.23kilogram")
    end
    assert_nothing_raised do
      55.23.in_kilogram
    end
    assert_nothing_raised do
      55.23.in(:kilogram)
    end
    assert_nothing_raised do
      55.23.in("kilogram")
    end
  end

  def test_convertions
    m = 1452.218534748545.in_ton
    assert_equal m.to_f, 1452.218534748545
    assert_equal m.to_d, 1452.218534748545
    assert_equal m.to_r, 1452.218534748545
  end


  def test_operations
    m1 = 155.in_kilogram
    m2 = 1.045.in_ton

    assert_equal m1, 0.155.in_ton
    assert_equal m2, 1.045.in_ton

    m3 = nil
    assert_nothing_raised do
      m3 = m1 + m2
    end
    assert_equal m3, 1.2.in_ton
    assert_equal m3, 1200.in_kilogram
    assert_equal m3, 1200000.in_gram

    assert_equal m3/2, 600.in_kilogram
    assert_equal m3*2, 2400.in_kilogram
    assert_equal m3*2.to_f, 2400.in_kilogram
    assert_equal m3*2.to_d, 2400.in_kilogram
    assert_equal m3*2.to_r, 2400.in_kilogram

    m4 = 1.2.in_cubic_meter

    assert_raise IncompatibleDimensions do
      m4 + m2
    end
  end

end
