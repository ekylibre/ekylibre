# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: subscription_natures
#
#  actual_number         :integer
#  created_at            :datetime         not null
#  creator_id            :integer
#  description           :text
#  entity_link_direction :string(30)
#  entity_link_nature    :string(120)
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  name                  :string(255)      not null
#  nature                :string(255)      not null
#  reduction_percentage  :decimal(19, 4)
#  updated_at            :datetime         not null
#  updater_id            :integer
#


class SubscriptionNature < Ekylibre::Record::Base
  # attr_accessible :actual_number, :description, :entity_link_direction, :entity_link_nature, :name, :nature, :reduction_percentage
  attr_readonly :nature
  enumerize :nature, in: [:period, :quantity], default: :period, predicates: true
  enumerize :entity_link_nature, in: Nomen::EntityLinkNatures.all
  enumerize :entity_link_direction, in: [:direct, :indirect, :all], default: :all, predicates: {prefix: true}
  has_many :products, class_name: "ProductNature"
  has_many :subscriptions, foreign_key: :nature_id

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :actual_number, allow_nil: true, only_integer: true
  validates_numericality_of :reduction_percentage, allow_nil: true
  validates_length_of :entity_link_direction, allow_nil: true, maximum: 30
  validates_length_of :entity_link_nature, allow_nil: true, maximum: 120
  validates_length_of :name, :nature, allow_nil: true, maximum: 255
  validates_presence_of :name, :nature
  #]VALIDATORS]
  validates_numericality_of :reduction_percentage, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100

  # default_scope -> { order(:name) }

  before_validation do
    self.reduction_percentage ||= 0
  end

  protect(on: :destroy) do
    self.subscriptions.count <= 0 and self.products.count <= 0
  end

  def now
    return (self.period? ? Date.today : self.actual_number)
  end

  def fields
    if self.period?
      return :started_on, :stopped_on
    else
      return :first_number, :last_number
    end
  end

  def start
    return fields[0]
  end

  def finish
    return fields[1]
  end

end

