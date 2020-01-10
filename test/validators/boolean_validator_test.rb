require 'test_helper'

class BooleanValidatable
  include ActiveModel::Validations
  attr_accessor :bool

  validates :bool, boolean: true
end

class BooleanValidatorTest < ActiveSupport::TestCase
  setup do
    @obj = BooleanValidatable.new
  end

  test 'boolean should be valid' do
    @obj.bool = true
    assert @obj.valid?

    @obj.bool = false
    assert@obj.valid?
  end

  test 'any other value is invalid' do
    @obj.bool = ''
    refute @obj.valid?

    @obj.bool = nil
    refute @obj.valid?

    @obj.bool = []
    refute @obj.valid?

    @obj.bool = 42
    refute @obj.valid?
  end
end
