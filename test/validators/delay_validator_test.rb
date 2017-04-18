# encoding: UTF-8

require 'test_helper'

class DelayValidatable
  include ActiveModel::Validations
  attr_accessor :delay

  validates_with DelayValidator, attributes: :delay
end

class DelayValidatorTest < ActiveSupport::TestCase
  setup do
    @obj = DelayValidatable.new
  end

  def test_invalidates_object_for_invalid_email
    @obj.delay = '30 days fdm'
    refute @obj.valid?
  end

  def test_adds_error_for_invalid_email
    @obj.delay = '30 days fdm'
    @obj.valid?

    assert_not_empty @obj.errors[:delay]
  end

  def test_adds_no_errors_for_valid_email
    @obj.delay = '30 days, fdm'

    assert       @obj.valid?
    assert_empty @obj.errors[:delay]
  end
end
