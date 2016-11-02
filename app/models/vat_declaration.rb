# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: vat_declarations
#
#  accounted_at      :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  description       :text
#  financial_year_id :integer          not null
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  number            :string
#  reference_number  :string
#  responsible_id    :integer
#  started_on        :date             not null
#  state             :string
#  stopped_on        :date             not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class VatDeclaration < Ekylibre::Record::Base
  include Attachable
  attr_readonly :currency
  refers_to :currency
  belongs_to :financial_year
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :responsible, class_name: 'User'
  has_many :items, class_name: 'VatDeclarationItem', dependent: :destroy, inverse_of: :vat_declaration
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :currency, :financial_year, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :reference_number, :state, length: { maximum: 500 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(vat_declaration) { vat_declaration.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]
  validates :number, uniqueness: true
  validates_associated :items

  acts_as_numbered
  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:tax_id].blank? && item[:tax].blank? }, allow_destroy: true

  state_machine :state, initial: :draft do
    state :draft
    state :validated
    state :sent
    event :propose do
      transition draft: :validated, if: :has_content?
    end
    event :confirm do
      transition validated: :sent, if: :has_content?
    end
  end
  
  before_validation(on: :create) do
    self.state ||= :draft
    self.currency = financial_year.currency if financial_year
    # if vat_declarations exists for current financial_year, then get the last to compute started_on
    if self.financial_year && self.financial_year.vat_declarations.any?
      self.started_on = self.financial_year.vat_declarations.reorder(:started_on).last.stopped_on + 1.day
    # else compute started_on from financial_year
    elsif self.financial_year
      self.started_on = self.financial_year.started_on
    end
    # anyway, stopped_on is started_on + vat_period_duration
    end_period = self.financial_year.vat_end_period
    if end_period
      self.stopped_on = self.started_on.send(end_period.to_s)
    end
  end

  before_validation do
    self.created_at ||= Time.zone.now
  end

  def has_content?
    items.any?
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(self.state.to_sym).human_name
  end

  def status
    return :go if sent?
    return :caution if validated?
    :stop
  end

  def deductible_vat_amount_balance
    return 0.0
  end

  def collected_vat_amount_balance
    return 0.0
  end

end
