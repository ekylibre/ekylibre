# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: manure_management_plans
#
#  annotation                 :text
#  campaign_id                :integer          not null
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  default_computation_method :string(255)      not null
#  id                         :integer          not null, primary key
#  lock_version               :integer          default(0), not null
#  locked                     :boolean          not null
#  name                       :string(255)      not null
#  opened_at                  :datetime         not null
#  recommender_id             :integer          not null
#  selected                   :boolean          not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#
class ManureManagementPlan < Ekylibre::Record::Base
  belongs_to :campaign
  belongs_to :recommender, class_name: "Entity"
  has_many :zones, class_name: "ManureManagementPlanZone", dependent: :destroy, inverse_of: :plan, foreign_key: :plan_id
  enumerize :default_computation_method, in: Nomen::ManureManagementPlanComputationMethods.all
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :opened_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_length_of :default_computation_method, :name, allow_nil: true, maximum: 255
  validates_inclusion_of :locked, :selected, in: [true, false]
  validates_presence_of :campaign, :default_computation_method, :name, :opened_at, :recommender
  #]VALIDATORS]

  accepts_nested_attributes_for :zones
  selects_among_all :selected, scope: :campaign_id

  scope :selecteds, -> { where(selected: true) }

  protect do
    self.locked?
  end

  after_save :compute

  def compute
    self.zones.map(&:compute)
  end

  def build_missing_zones
    active = false
    active = true if self.zones.empty?
    return false unless self.campaign
    for support in campaign.production_supports.includes(:storage).order(:production_id, "products.name")
      # support.active? return all activies except fallow_land
      if support.storage.is_a?(CultivableZone) and support.active?
        unless self.zones.find_by(support: support)
          zone = self.zones.build(support: support, computation_method: self.default_computation_method, administrative_area: support.storage.administrative_area, cultivation_variety: support.production_variant.variety, soil_nature: support.storage.soil_nature || support.storage.estimated_soil_nature)
          zone.estimate_expected_yield
        end
      end
    end
  end

  def mass_density_unit
    :quintal_per_hectare
  end

end
