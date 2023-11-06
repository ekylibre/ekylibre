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
# == Table: payslips
#
#  account_id       :integer(4)
#  accounted_at     :datetime
#  affair_id        :integer(4)
#  amount           :decimal(19, 4)   not null
#  created_at       :datetime         not null
#  creator_id       :integer(4)
#  currency         :string           not null
#  custom_fields    :jsonb
#  emitted_on       :date
#  employee_id      :integer(4)
#  id               :integer(4)       not null, primary key
#  journal_entry_id :integer(4)
#  lock_version     :integer(4)       default(0), not null
#  nature_id        :integer(4)       not null
#  number           :string           not null
#  started_on       :date             not null
#  state            :string           not null
#  stopped_on       :date             not null
#  updated_at       :datetime         not null
#  updater_id       :integer(4)
#

class Payslip < ApplicationRecord
  include Attachable
  include Customizable
  belongs_to :account
  belongs_to :affair
  belongs_to :employee, class_name: 'Entity'
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :nature, class_name: 'PayslipNature'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :number, :state, presence: true, length: { maximum: 500 }
  validates :emitted_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(payslip) { payslip.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :nature, presence: true
  # ]VALIDATORS]
  validates :emitted_on, presence: { if: :invoice? }
  validates :amount, numericality: { greater_than: 0 }
  validates :employee, presence: true

  delegate :with_accounting, to: :nature
  delegate :imported_centralizing_entries, to: :nature

  alias_attribute :third_id, :employee_id

  acts_as_numbered
  acts_as_affairable :employee, class_name: 'PayslipAffair'

  before_validation do
    self.state ||= :draft
    if nature
      self.currency = nature.currency
      self.account ||= nature.account if nature.account
    end
    self.emitted_on ||= Time.zone.today if invoice?
  end

  validate do
    if with_accounting
      amount_accountancy_equality
    end
  end

  state_machine :state, initial: :draft do
    state :draft
    state :invoice
    event :invoice do
      transition draft: :invoice
    end
    event :correct do
      transition invoice: :draft, if: :has_no_entry?
    end
  end

  protect do
    (journal_entry && (journal_entry.closed? || journal_entry.confirmed?))
  end

  # This callback permits to add journal entries corresponding to the payslip
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  ## imported_centralizing_entries
  # C 421XX  amount
  # D 421    amount
  ## no imported_centralizing_entries
  # C 421XX  amount
  # C 431    social_security_amount
  # C 437    other_social_expenses_amount
  # C 4421   source_revenue_amount
  # D 6411   raw_amount
  # D 645    total_company_social_amount
  bookkeep do |b|
    if imported_centralizing_entries
      b.journal_entry(nature.journal, printed_on: emitted_on, if: (with_accounting && invoice?)) do |entry|
        label = tc(:bookkeep, resource: self.class.model_name.human, number: number, employee: employee.full_name, started_on: started_on.l, stopped_on: stopped_on.l)
        # amount
        entry.add_credit(label, employee.account(:employee).id, amount, as: :employee)
        # compensation_amount
        entry.add_debit(label, (account || nature.account || Account.find_or_import_from_nomenclature(:staff_due_remunerations)).id, amount, as: :expense)
      end
    else
      b.journal_entry(nature.journal, printed_on: emitted_on, if: (with_accounting && invoice?)) do |entry|
        label = tc(:bookkeep, resource: self.class.model_name.human, number: number, employee: employee.full_name, started_on: started_on.l, stopped_on: stopped_on.l)
        # amount
        entry.add_credit(label, employee.account(:employee).id, amount, as: :employee)
        # social_security_amount
        entry.add_credit(label, Account.find_or_import_from_nomenclature(:social_security).id, social_security_amount, as: :expense)
        # other_social_expenses_amount
        entry.add_credit(label, Account.find_or_import_from_nomenclature(:other_social_organisation).id, other_social_expenses_amount, as: :expense)
        # source_revenue_amount
        entry.add_credit(label, Account.find_or_import_from_nomenclature(:source_revenue_taxes).id, source_revenue_amount, as: :expense)
        # raw_amount
        entry.add_debit(label, (account || nature.account || Account.find_or_import_from_nomenclature(:staff_expenses)).id, amount, as: :expense)
        # total_company_social_amount
        entry.add_debit(label, Account.find_or_import_from_nomenclature(:salary_social_contribution_expenses).id, total_company_social_amount, as: :expense)
      end
    end
  end

  def amount_accountancy_equality
    if imported_centralizing_entries == false && credit_account_part.to_f != debit_account_part.to_f
      errors.add(:amount, :amounts_are_not_balanced)
    end
  end

  def credit_account_part
    amount + source_revenue_amount + social_security_amount + other_social_expenses_amount
  end

  def debit_account_part
    raw_amount + total_company_social_amount
  end

  def label
    number
  end

  def has_no_entry?
    journal_entry&.draft?
  end

  def human_status
    I18n.t("tooltips.models.payslip.#{status}")
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(self.state.to_sym).human_name
  end

  def status
    return affair.status if invoice?

    :stop
  end

  def self.affair_class
    PayslipAffair
  end

  def self.third_attribute
    :employee
  end

  def default_currency
    currency || nature.currency
  end

  def precision
    Onoma::Currency.find(currency).precision
  end

  def refresh
    save
  end

  def third
    send(third_attribute)
  end
  delegate :third_attribute, to: :class
end
