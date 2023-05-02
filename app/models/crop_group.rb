# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: crop_groups
#
#  created_at   :datetime         not null
#  creator_id   :integer(4)
#  id           :integer(4)       not null, primary key
#  lock_version :integer(4)       default(0), not null
#  name         :string           not null
#  target       :string           default("plant")
#  updated_at   :datetime         not null
#  updater_id   :integer(4)
#
class CropGroup < ApplicationRecord
  enumerize :target, in: %i[plant land_parcel], predicates: true, default: :plant

  has_many :labellings, class_name: 'CropGroupLabelling', dependent: :destroy
  has_many :items, class_name: 'CropGroupItem', dependent: :destroy
  has_many :plants, through: :items, source: :crop, source_type: 'Plant'
  has_many :land_parcels, through: :items, source: :crop, source_type: 'LandParcel'
  has_many :labels, through: :labellings
  has_many :intervention_crop_groups, dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]

  accepts_nested_attributes_for :labellings, allow_destroy: true, reject_if: :label_already_present
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :crop_already_present

  scope :available_crops, ->(ids, expression) { Product.joins(:crop_groups).where('crop_groups.id IN (?) ', Array(ids)).of_expression(expression).distinct }
  scope :collection_labels, ->(ids, type = %w[plant land_parcel]) { where(id: ids, target: type).collect(&:labels).flatten.uniq }

  def crops
    Crop.all.joins(:crop_group_items)
           .where('crop_group_items.crop_group_id = ?', id)
  end

  def label_names
    labels.collect(&:name).sort.join(', ')
  end

  def crop_names
    crops.collect(&:name).sort.join(', ')
  end

  def total_area
    crops.collect(&:net_surface_area).sum.in(:hectare)
  end

  def crop_estimated_vine_stock
    self.plants.map(&:estimated_vine_stock).compact.sum
  end

  def crop_missing_vine_stock
    self.plants.map(&:missing_vine_stock).compact.sum
  end

  private

    def label_already_present(attributes)
      labellings.reject(&:marked_for_destruction?).map(&:label_id).include?(attributes[:label_id].to_i)
    end

    def crop_already_present(attributes)
      items.reject(&:marked_for_destruction?).map(&:crop_id).include?(attributes[:crop_id].to_i)
    end
end
