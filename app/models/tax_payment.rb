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
# == Table: tax_payments
#
#  accounted_at      :datetime
#  amount            :decimal(19, 4)   default(0.0), not null
#  cash_id           :integer(4)       not null
#  created_at        :datetime         not null
#  creator_id        :integer(4)
#  currency          :string           not null
#  description       :text
#  id                :integer(4)       not null, primary key
#  financial_year_id :integer(4)       not null
#  journal_entry_id  :integer(4)
#  lock_version      :integer(4)       default(0), not null
#  number            :string
#  paid_at           :datetime         not null
#  nature            :string           not null
#  state             :string           not null
#  updated_at        :datetime         not null
#  updater_id        :integer(4)
#

class TaxPayment < ApplicationRecord
  include Attachable
  include Letterable
  attr_readonly :currency
  refers_to :currency
  enumerize :nature, in: %i[incoming_payment outgoing_payment advance_payment], predicates: true
  belongs_to :cash
  belongs_to :financial_year
  belongs_to :journal_entry, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :financial_year, :nature, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :state, presence: true, length: { maximum: 500 }
  validates :paid_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  # ]VALIDATORS]
  validates :number, uniqueness: true

  acts_as_numbered

  state_machine :state, initial: :draft do
    state :draft
    state :validated
    event :confirm do
      transition draft: :validated
    end
  end

  before_validation(on: :create) do
    self.state ||= :draft
    self.paid_at ||= Time.now
    if financial_year
      self.currency = financial_year.currency
    end
  end

  protect do
    (journal_entry && journal_entry.closed?) ||
    pointed_by_bank_statement?
  end

  # This method permits to add journal entries corresponding to the vat payment
  bookkeep do |b|
    label = tc(:bookkeep, resource: self.class.model_name.human, number: number, mode: nature_label, year: financial_year.code)
    # FR : Demande de remboursement 3519
    if nature == :incoming_payment
      account = Account.find_or_import_from_nomenclature(:report_vat_credit)
      request_account = Account.find_or_import_from_nomenclature(:refund_request_vat_payment_taxes)
      # C '44567'
      # D '44583'
      # C '44583'
      # D '511X'
      b.journal_entry(cash.journal, printed_on: paid_at.to_date, if: validated?) do |entry|
        entry.add_credit(label, account.id, amount, as: :vat)
        entry.add_debit(label, request_account.id, amount, as: :request_vat)
        entry.add_credit(label, request_account.id, amount, as: :request_vat)
        entry.add_debit(label, cash.account_id, amount, as: :bank)
      end
    # FR : Paiement
    elsif nature == :outgoing_payment
      account = Account.find_or_import_from_nomenclature(:vat_to_pay)
      # D '44551'
      # C '511X'
      b.journal_entry(cash.journal, printed_on: paid_at.to_date, if: validated?) do |entry|
        entry.add_debit(label, account.id, amount, as: :vat)
        entry.add_credit(label, cash.account_id, amount, as: :bank)
      end
    # FR : Acompte
    elsif nature == :advance_payment
      account = Account.find_or_import_from_nomenclature(:advance_vat_payment_taxes)
      # D '44581'
      # C '511X'
      b.journal_entry(cash.journal, printed_on: paid_at.to_date, if: validated?) do |entry|
        entry.add_debit(label, account.id, amount, as: :vat)
        entry.add_credit(label, cash.account_id, amount, as: :bank)
      end
    end
  end

  def status
    return :go if validated?
    return :caution if draft?

    :stop
  end

  def human_status
    I18n.t("tooltips.models.tax_payment.#{status}")
  end

  def state_label
    I18n.t("enumerize.tax_payment.state.#{self.state.to_sym}")
  end

  def nature_label
    I18n.t("enumerize.tax_payment.nature.#{self.nature.to_sym}")
  end

  def relative_amount
    if nature.present? && nature == :incoming_payment
      amount
    elsif nature.present?
      -1 * amount
    end
  end

  def pointed_by_bank_statement?
    journal_entry && journal_entry.items.where('LENGTH(TRIM(bank_statement_letter)) > 0').any?
  end

end
