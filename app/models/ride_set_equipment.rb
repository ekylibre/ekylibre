# frozen_string_literal: true

class RideSetEquipment < ApplicationRecord
  include Providable
  belongs_to :ride_set
  belongs_to :product

  enumerize :nature, in: %i[main additional]
  delegate :name, to: :product

  scope :of_nature, ->(nature) {
    where(nature: nature).limit(2)
  }
end
