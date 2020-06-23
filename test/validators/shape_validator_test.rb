require 'test_helper'

class ShapeValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

  INVALID_SHAPE = Charta.new_geometry(<<~EWKT).freeze
      SRID=4326;MultiPolygon (((4.908266058720982 46.91016375994975, 4.908266060002689 46.91016375902789, 4.90865146378712 46.91013522972928, 4.908857900381218 46.91012736923464, 4.908855557441711 46.9101271141826, 4.908828735351563 46.9101271141826, 4.908834099769592 46.91017475492051, 4.908867665754878 46.91012750102963, 4.908899977650015 46.91024305558259, 4.909021604251901 46.91053652156399, 4.909181736780146 46.91093084006668, 4.90863561630249 46.91103228096193, 4.908447861671448 46.91059985501492, 4.908266040459607 46.91016376385473, 4.908266056189317 46.91016376269356, 4.908266058720982 46.91016375994975)))
  EWKT
  VALID_SHAPE = Charta.new_geometry(<<~EWKT).freeze
      SRID=4326;MultiPolygon (((1 1, 1 2, 2 2, 2 1)))
  EWKT

  class ShapeStrictValidatable
    include ActiveModel::Validations
    attr_accessor :shape

    validates :shape, shape: true, presence: true
  end

  test 'shape strict validation rejects nil and empty' do
    obj = ShapeStrictValidatable.new
    obj.shape = nil
    assert_not obj.valid?

    obj.shape = Charta::empty_geometry
    assert_not obj.valid?
    assert_equal "The shape of Shape cannot be empty", obj.errors.messages.fetch(:shape).first
  end

  test 'shape validation reject invalid shapes' do
    obj = ShapeStrictValidatable.new
    obj.shape = INVALID_SHAPE

    assert_not obj.valid?
    assert_equal "The geographic shape for Shape is invalid", obj.errors.messages.fetch(:shape).first
  end

  test 'shape validation accept valid shapes' do
    obj = ShapeStrictValidatable.new
    obj.shape = VALID_SHAPE

    assert obj.valid?
  end
end
