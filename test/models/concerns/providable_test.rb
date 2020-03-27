require 'test_helper'

class ProvidableTest < Ekylibre::Testing::ApplicationTestCase
  class ParentClass
    attr_accessor :provider

    def self.scope(*)
    end
  end

  class ModelClass < ParentClass
    include Providable
  end

  test 'provider_data should return an empty hash' do
    truc = ModelClass.new

    assert_equal({}, truc.provider_data)
  end

  test 'provider_data = should set the value for the data key' do
    model = ModelClass.new

    model.provider_data = 42

    assert_equal(42, model.provider_data)
    assert_equal({ data: 42 }, model.provider)
  end

  test 'provider data should only modify the data key' do
    model = ModelClass.new
    model.provider = { name: "test" }

    model.provider_data = 42


    assert_equal(42, model.provider_data)
    assert_equal({ name: "test", data: 42 }, model.provider)
  end

  test 'provider = should filter out unwanted keys' do
    model = ModelClass.new
    model.provider = { key: "test" }

    assert_equal({}, model.provider)
  end

  test 'provider convenience getter return the correct values' do
    model = ModelClass.new
    model.provider = { vendor: "Ekylibre", name: "zero", id: 0 }

    assert_equal('Ekylibre', model.provider_vendor)
    assert_equal('zero', model.provider_name)
    assert_equal(0, model.provider_id)
  end

  test 'provided_by? = ' do
    model = ModelClass.new
    model.provider = { vendor: "Ekylibre", name: "zero", id: 0 }

    assert model.is_provided_by?(vendor: "Ekylibre", name: "zero", id: 0)
    refute model.is_provided_by?(vendor: "Ekylibrre", name: "zero", id: 0)
    assert model.is_provided_by?(vendor: "Ekylibre", name: "zero")
    refute model.is_provided_by?(vendor: "Ekylibre", name: "zero", id: 42)
  end
end
