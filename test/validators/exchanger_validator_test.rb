require 'test_helper'

class ExchangerValidatable
  include ActiveModel::Validations
  attr_accessor :exchanger

  validates :exchanger, exchanger: true
end
class ExchangerValidatableWithTransformMethod
  include ActiveModel::Validations
  attr_accessor :id
  validates :id, exchanger: { transform: :exchanger_name }

  def exchanger_name; end
end
class ExchangerValidatableWithTransformCallable
  include ActiveModel::Validations
  attr_accessor :id
  validates :id, exchanger: { transform: ->(_record, _value) { 'other_exchanger_name' } }

end

class ExchangerValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

  setup do
    @exchangers = ActiveExchanger::Base.exchangers
    ActiveExchanger::Base.exchangers = {
      valid_exchanger_name: Object,
      other_exchanger_name: Object
    }
  end

  teardown do
    ActiveExchanger::Base.exchangers = @exchangers
  end

  test 'fails when exchanger name does not exist' do
    record = ExchangerValidatable.new
    record.exchanger = "invalid_name"

    assert_not record.valid?
    assert_equal 1, record.errors.messages[:exchanger].count
  end

  test 'valid when exchanger name exists' do
    record = ExchangerValidatable.new
    record.exchanger = "valid_exchanger_name"

    assert record.valid?
  end

  test 'calls the method to get exchanger name when symbol is passed as transform parameter' do
    record = ExchangerValidatableWithTransformMethod.new
    record.stub :exchanger_name, "valid_exchanger_name" do
      assert record.valid?
    end
  end

  test 'use the callable to get exchanger name when callable is passed as transform parameter' do
    record = ExchangerValidatableWithTransformCallable.new
    assert record.valid?
  end

end
