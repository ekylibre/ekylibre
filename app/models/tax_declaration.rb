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
# == Table: tax_declarations
#
#  accounted_at      :datetime
#  affair_id         :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  description       :text
#  financial_year_id :integer          not null
#  id                :integer          not null, primary key
#  invoiced_at       :datetime
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  number            :string
#  reference_number  :string
#  responsible_id    :integer
#  started_on        :date             not null
#  state             :string
#  stopped_on        :date             not null
#  tax_office_id     :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class TaxDeclaration < Ekylibre::Record::Base
  include Attachable
  attr_readonly :currency
  refers_to :currency
  belongs_to :financial_year
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :responsible, class_name: 'User'
  belongs_to :tax_office, class_name: 'Entity'
  has_many :items, class_name: 'TaxDeclarationItem', dependent: :destroy, inverse_of: :tax_declaration
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :invoiced_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :currency, :financial_year, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :reference_number, :state, length: { maximum: 500 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(tax_declaration) { tax_declaration.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]
  validates :number, uniqueness: true
  validates_associated :items

  acts_as_numbered
  # acts_as_affairable :tax_office
  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:tax_id].blank? && item[:tax].blank? }, allow_destroy: true

  delegate :vat_mode, :vat_period, to: :financial_year

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
    # if tax_declarations exists for current financial_year, then get the last to compute started_on
    if financial_year && financial_year.tax_declarations.any?
      self.started_on = financial_year.tax_declarations.reorder(:started_on).last.stopped_on + 1.day
    # else compute started_on from financial_year
    elsif financial_year
      self.started_on = financial_year.started_on
    end
    # anyway, stopped_on is started_on + vat_period_duration
    end_period = financial_year.vat_end_period
    self.stopped_on = started_on.send(end_period.to_s) if end_period
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

  # This callback bookkeeps the sale depending on its state
  bookkeep do |b|
    # FIXME : add vat journal in default journal
    vat_journal = Journal.create_with(name: :vat.tl).find_or_create_by!(nature: 'various', code: 'VAT', currency: currency)
    # FIXME : put account in tax_office entity
    credit_vat_account = Account.find_or_create_by_number(45_567)
    debit_vat_account = Account.find_or_create_by_number(44_551)
    b.journal_entry(vat_journal, printed_on: invoiced_on, if: (has_content? && validated?)) do |entry|
      # FIXME: add correct label on bookkeep
      label = tc(:bookkeep, resource: state_label, number: number)
      items.each do |item|
        entry.add_debit(label, item.tax.collect_account.id, item.collected_vat_amount.round(2)) unless item.collected_vat_amount.zero?
        entry.add_credit(label, item.tax.deduction_account.id, item.deductible_vat_amount.round(2)) unless item.deductible_vat_amount.zero?
        entry.add_credit(label, item.tax.fixed_asset_deduction_account.id, item.fixed_asset_deductible_vat_amount.round(2)) unless item.fixed_asset_deductible_vat_amount.zero?
      end
      vat_balance = items.map(&:balance).compact.sum.round(2)
      entry.add_credit(label, (vat_balance < 0 ? credit_vat_account : debit_vat_account), vat_balance) unless vat_balance.zero?
    end
  end

  def invoiced_on
    dealt_at.to_date
  end

  def dealt_at
    (validated? ? invoiced_at : created_at? ? self.created_at : Time.zone.now)
  end

  def status
    return :go if sent?
    return :caution if validated?
    :stop
  end

  def deductible_vat_amount_balance
    items.map(&:deductible_vat_amount).compact.sum
  end

  def collected_vat_amount_balance
    items.map(&:collected_vat_amount).compact.sum
  end
end
