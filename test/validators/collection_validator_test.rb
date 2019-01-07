require 'test_helper'

class CollectionValidatable
  include ActiveModel::Validations
  attr_accessor :collection

  validates :collection, collection: true
end

class CollectionValidatorTest < ActiveSupport::TestCase
  setup do
    @obj = CollectionValidatable.new
    @invalid = Object.new

    def @invalid.invalid?
      true
    end

    @valid = Object.new

    def @valid.invalid?
      false
    end
  end

  test 'other type than array are not valid' do
    @obj.collection = 42
    refute @obj.valid?

    @obj.collection = nil
    refute @obj.valid?
  end

  test 'empty collection should be valid' do
    @obj.collection = []

    assert @obj.valid?
  end

  test 'valid if all elements in collection are valid' do
    @obj.collection = [@valid]

    assert @obj.valid?
  end

  test 'ivalid if any element is invalid' do
    @obj.collection = [@valid, @invalid]

    refute @obj.valid?
  end

end
