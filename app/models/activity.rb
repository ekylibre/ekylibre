# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
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
# == Table: activities
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  depth        :integer
#  description  :string(255)
#  family       :string(255)
#  id           :integer          not null, primary key
#  lft          :integer
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(255)      not null
#  parent_id    :integer
#  rgt          :integer
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Activity < Ekylibre::Record::Base
  # attr_accessible :started_at, :stopped_at, :nature, :description, :family, :name, :parent_id, :productions_attributes
  enumerize :nature, in: [:main, :auxiliary, :none], default: :main
  enumerize :family, in: Nomen::ActivityFamilies.all, predicates: true
  has_many :productions
  has_many :supports, through: :productions
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :depth, :lft, :rgt, allow_nil: true, only_integer: true
  validates_length_of :description, :family, :name, :nature, allow_nil: true, maximum: 255
  validates_presence_of :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :family, in: self.family.values, allow_nil: true

  scope :main, -> { where(nature: "main") }
  # scope :main_activity, -> { where(nature: "main") }
  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    # joins(:productions).merge(Production.of_campaign(campaigns))
    # where("id IN (SELECT activity_id FROM #{Production.table_name} WHERE campaign_id IN (?))", campaigns.map(&:id))
    where("id IN (?)", Production.of_campaign(campaigns).pluck(:activity_id))
  }

  #scope :of_families, lambda { |*families|
  #  where("family ~ E?", "\\\\m(" + families.flatten.sort.join("|") + ")\\\\M")
  #}

  scope :of_families, Proc.new { |*families|
    where(:family => families.flatten.collect{|f| Nomen::ActivityFamilies.all(f.to_sym) }.flatten.uniq.map(&:to_s))
  }

  protect(on: :destroy) do
    self.productions.any?
  end

  accepts_nested_attributes_for :productions, :reject_if => :all_blank, :allow_destroy => true
  acts_as_nested_set

  def shape_area(*campaigns)
    return productions.of_campaign(campaigns).map(&:shape_area).compact.sum
  end

  def net_surface_area(*campaigns)
    return productions.of_campaign(campaigns).map(&:net_surface_area).compact.sum
  end

  def area(*campaigns)
    ActiveSupport::Deprecation.warn("#{self.class.name}#area is deprecated. Please use #{self.class.name}#net_surface_area instead.")
    return net_surface_area(*campaigns)
  end

  def interventions_duration(*campaigns)
    return productions.of_campaign(campaigns).map(&:duration).compact.sum
  end

  def is_of_family?(family)
    Nomen::ActivityFamilies.all(family).include?(self.family.to_s)
  end

end
