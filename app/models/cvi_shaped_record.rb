# frozen_string_literal: true

class CviShapedRecord < ApplicationRecord
  self.abstract_class = true

  before_save :set_calculated_area, on: %i[create update], if: :shape_changed?

  scope :in_bounding_box, lambda { |bounding_box|
    where("#{self.table_name}.shape && ST_MakeEnvelope(#{bounding_box})")
  }

  def shape
    Charta.new_geometry(self[:shape])
  end

  def shape_changed?
    Charta.new_geometry(shape_was) != shape
  end

  def set_calculated_area
    self.calculated_area = Measure.new(shape.area, :square_meter).convert(:hectare)
  end
end
