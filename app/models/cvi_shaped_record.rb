# frozen_string_literal: true

class CviShapedRecord < ApplicationRecord
  self.abstract_class = true

  # `:on` n'est pas une option de `before_save` : elle ne vaut que pour
  # `before_validation` et les rappels de commit. Rails 5 l'ignorait, Rails 6
  # lève `Unknown key: :on`. `%i[create update]` couvrait de toute façon les
  # deux cas, c'est-à-dire exactement ce que fait `before_save` sans option.
  before_save :set_calculated_area, if: :shape_changed?

  scope :in_bounding_box, lambda { |bounding_box|
    where("#{self.table_name}.shape && ST_MakeEnvelope(#{bounding_box})")
  }

  def shape
    Charta.new_geometry(self[:shape])
  end

  def shape_changed?
    Charta.new_geometry(shape_before_last_save) != shape
  end

  def set_calculated_area
    self.calculated_area = Measure.new(shape.area, :square_meter).convert(:hectare)
  end
end
