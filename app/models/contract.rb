# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: contracts
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  custom_fields    :jsonb
#  description      :string
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  number           :string
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  reference_number :string
#  responsible_id   :integer          not null
#  started_on       :date
#  state            :string
#  stopped_on       :date
#  supplier_id      :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Contract < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency
  refers_to :currency
  belongs_to :supplier, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  has_many :parcels
  has_many :purchases
  has_many :items, class_name: 'ContractItem', dependent: :destroy, inverse_of: :contract
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :currency, :responsible, :supplier, presence: true
  validates :description, :number, :reference_number, :state, length: { maximum: 500 }, allow_blank: true
  validates :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :started_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :stopped_on, timeliness: { on_or_after: ->(contract) { contract.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]
  validates :number, :state, length: { allow_nil: true, maximum: 60 }
  validates :state, presence: true
  validates :number, uniqueness: true
  validates_associated :items

  acts_as_numbered

  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:variant_id].blank? && item[:variant].blank? }, allow_destroy: true

  scope :of_supplier, ->(supplier) { where(supplier_id: (supplier.is_a?(Entity) ? supplier.id : supplier)) }

  state_machine :state, initial: :prospecting do
    state :prospecting
    state :price_quote
    state :negociation
    state :won
    state :lost

    event :prospect do
      transition all => :prospecting
    end

    event :quote do
      transition all => :price_quote
    end

    event :negociate do
      transition all => :negociation
    end

    event :win do
      transition all => :won
    end

    event :lose do
      transition all => :lost
    end
  end

  before_validation(on: :create) do
    self.state ||= :prospecting
    self.currency = Preference[:currency]
    self.pretax_amount = items.sum(:pretax_amount)
  end

  before_validation do
    self.created_at ||= Time.zone.now
    self.pretax_amount = items.sum(:pretax_amount)
  end

  after_create do
    supplier.add_event(:contract_creation, updater.person) if updater
  end

  protect on: :destroy do
    parcels.any? || purchases.any?
  end

  def has_content?
    items.any?
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(self.state.to_sym).human_name
  end

  # Returns dayleft in day of the contract
  def dayleft(on = Date.today)
    return nil if started_on.nil? || stopped_on <= on
    (stopped_on - on)
  end

  def status
    return :go if won?
    return :stop if lost?
    :caution
  end
end
