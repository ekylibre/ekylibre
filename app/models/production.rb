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
# == Table: productions
#
#  activity_id       :integer          not null
#  campaign_id       :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  position          :integer
#  product_nature_id :integer          not null
#  started_at        :datetime
#  state             :string(255)
#  static_support    :boolean          not null
#  stopped_at        :datetime
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class Production < Ekylibre::Record::Base
  attr_accessible :activity_id, :product_nature_id, :campaign_id, :static_support, :state, :started_at, :stopped_at
  belongs_to :activity
  belongs_to :campaign
  # belongs_to :area_unit, :class_name => "Unit"
  belongs_to :product_nature
  has_many :repartitions, :class_name => "ActivityRepartition"
  has_many :supports, :class_name => "ProductionSupport", :inverse_of => :production

  accepts_nested_attributes_for :supports, :reject_if => :all_blank, :allow_destroy => true
  #belongs_to :storage, :class_name => "LandParcel"
  # belongs_to :work_unit, :class_name => "Unit"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :state, :allow_nil => true, :maximum => 255
  validates_inclusion_of :static_support, :in => [true, false]
  validates_presence_of :activity, :campaign, :product_nature
  #]VALIDATORS]

  state_machine :state, :initial => :draft do
    state :draft
    state :validated
    state :started
    state :aborted

    event :correct do
      transition :validated => :draft
    end

    event :confirm do
      transition :draft => :validated, :if => :has_active_product?
    end

    event :start do
      transition :validated => :started, :if => :has_active_product?
    end

    event :abort do
      # transition [:draft, :estimate] => :aborted # , :order
      transition :draft => :aborted # , :order
    end
  end

  before_validation(:on => :create) do
    self.state ||= self.class.state_machine.initial_state(self)
  end

  def has_active_product?
    self.product_nature.active?
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # Prints human name of current production
  def state_label
    self.class.state_label(self.state)
  end

  def name
    tc('label.' + self.state, :identification => (self.product_nature.name + " " + self.campaign.name))
   end
  alias :label :name


end
