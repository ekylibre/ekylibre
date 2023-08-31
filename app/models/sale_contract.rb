# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: sale_contracts
#
#  client_id           :integer          not null
#  closed              :boolean          default(FALSE), not null
#  comment             :text
#  created_at          :datetime         not null
#  creator_id          :integer
#  currency            :string           not null
#  custom_fields       :jsonb
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string           not null
#  nature_id           :integer
#  number              :string
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  responsible_id      :integer
#  sale_opportunity_id :integer
#  started_on          :date
#  stopped_on          :date
#  updated_at          :datetime         not null
#  updater_id          :integer
#

class SaleContract < ApplicationRecord
  include Attachable
  include Customizable
  attr_readonly :currency
  refers_to :currency
  belongs_to :client, class_name: 'Entity'
  belongs_to :responsible, class_name: 'Entity'
  belongs_to :sale_opportunity, inverse_of: :sale_contracts
  belongs_to :nature, class_name: 'SaleContractNature'
  has_many :items, class_name: 'SaleContractItem', dependent: :destroy, inverse_of: :sale_contract
  has_many :projects, class_name: 'Project', inverse_of: :sale_contract
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed, inclusion: { in: [true, false] }
  validates :comment, length: { maximum: 500_000 }, allow_blank: true
  validates :client, :currency, presence: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :started_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :stopped_on, timeliness: { on_or_after: ->(sale_contract) { sale_contract.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 60 }
  validates :number, uniqueness: true
  validates_associated :items

  acts_as_numbered

  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:variant_id].blank? && item[:variant].blank? }, allow_destroy: true

  scope :of_client, ->(client) { where(client_id: (client.is_a?(Entity) ? client.id : client)) }

  before_validation(on: :create) do
    self.currency = Preference[:currency]
    self.pretax_amount = items.sum(:pretax_amount)
  end

  before_validation do
    self.created_at ||= Time.zone.now
    self.pretax_amount = items.sum(:pretax_amount)
  end

  protect on: :destroy do
    sale_opportunity || projects.any?
  end

  def has_content?
    items.any?
  end

  # Returns dayleft in day of the contract
  def dayleft(on = Date.today)
    return nil if started_on.nil? || stopped_on.nil?

    if stopped_on <= on
      0
    else
      (stopped_on - on).round(0)
    end
  end
end
