# frozen_string_literal: true

class ReferenceUnit < Unit

  validates :base_unit, presence: true, unless: :dimension_reference_unit?

  scope :of_dimensions, ->(*dimensions) { where(dimension: dimensions) }

  after_save do
    self.update_column(:base_unit_id, id) if dimension_reference_unit?
  end

  def dimension_reference_unit?
    BASE_UNIT_PER_DIMENSION.values.include?(reference_name)
  end
end
