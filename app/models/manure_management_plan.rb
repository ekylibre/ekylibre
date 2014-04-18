# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: manure_management_plans
#
#  annotation                 :text
#  campaign_id                :integer          not null
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  default_computation_method :string(255)      not null
#  exploitation_typology      :string(255)
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
  has_many :zones, class_name: "ManureManagementPlanZone", inverse_of: :plan, foreign_key: :plan_id
  enumerize :default_computation_method, in: Nomen::ManureManagementPlanComputationMethods.all
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :default_computation_method, :exploitation_typology, :name, allow_nil: true, maximum: 255
  validates_inclusion_of :locked, :selected, in: [true, false]
  validates_presence_of :campaign, :default_computation_method, :name, :opened_at, :recommender
  #]VALIDATORS]

  accepts_nested_attributes_for :zones
  selects_among_all scope: :campaign_id

  protect do
    self.locked?
  end

  after_save :compute

  def compute
  end

  def build_missing_zones
    active = false
    active = true if self.zones.empty?
    for support in campaign.production_supports.includes(:storage).order(:production_id, "products.name")
      # support.active? return all activies except fallow_land
      if support.storage.is_a?(CultivableZone) and support.active?
        for membership in support.storage.memberships
          unless self.zones.find_by(support: support, membership: membership)
            self.zones.build(support: support, membership: membership, computation_method: self.default_computation_method)
          end
        end
      end
    end
  end

end
