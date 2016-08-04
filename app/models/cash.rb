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
# == Table: cashes
#
#  account_id           :integer          not null
#  bank_account_key     :string
#  bank_account_number  :string
#  bank_agency_address  :text
#  bank_agency_code     :string
#  bank_code            :string
#  bank_identifier_code :string
#  bank_name            :string
#  container_id         :integer
#  country              :string
#  created_at           :datetime         not null
#  creator_id           :integer
#  currency             :string           not null
#  custom_fields        :jsonb
#  iban                 :string
#  id                   :integer          not null, primary key
#  journal_id           :integer          not null
#  last_number          :integer
#  lock_version         :integer          default(0), not null
#  mode                 :string           default("iban"), not null
#  name                 :string           not null
#  nature               :string           default("bank_account"), not null
#  owner_id             :integer
#  spaced_iban          :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#

class Cash < Ekylibre::Record::Base
  include Attachable
  include Customizable
  BBAN_TRANSLATIONS = {
    fr: %w(abcdefghijklmonpqrstuvwxyz 12345678912345678923456789)
  }.freeze
  attr_readonly :nature
  attr_readonly :currency, if: :used?
  refers_to :country
  refers_to :currency
  belongs_to :account
  belongs_to :container, class_name: 'Product'
  belongs_to :journal
  belongs_to :owner, class_name: 'Entity'
  has_many :active_sessions, -> { actives }, class_name: 'CashSession'
  has_many :bank_statements, dependent: :destroy
  has_many :deposits
  has_many :journal_entry_items, through: :account
  has_many :outgoing_payment_modes
  has_many :incoming_payment_modes
  has_many :sessions, class_name: 'CashSession'
  has_many :unpointed_journal_entry_items, -> { where(bank_statement_letter: nil) }, through: :account, source: :journal_entry_items
  has_one :last_bank_statement, -> { order(stopped_on: :desc) }, class_name: 'BankStatement'

  enumerize :nature, in: [:bank_account, :cash_box, :associate_account], default: :bank_account, predicates: true
  enumerize :mode, in: [:iban, :bban], default: :iban, predicates: { prefix: true }
  # refers_to :currency

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :bank_account_key, :bank_account_number, :bank_agency_code, :bank_code, :bank_identifier_code, :bank_name, :iban, :spaced_iban, length: { maximum: 500 }, allow_blank: true
  validates :bank_agency_address, length: { maximum: 100_000 }, allow_blank: true
  validates :account, :currency, :journal, :mode, :nature, presence: true
  validates :last_number, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :country, length: { allow_blank: true, maximum: 2 }
  validates :currency, length: { allow_blank: true, maximum: 3 }
  validates :bank_identifier_code, length: { allow_blank: true, maximum: 11 }
  validates :nature, length: { allow_blank: true, maximum: 20 }
  validates :iban, length: { allow_blank: true, maximum: 34 }
  validates :spaced_iban, length: { allow_blank: true, maximum: 42 }
  validates :bank_name, length: { allow_blank: true, maximum: 50 }
  validates :mode, inclusion: { in: mode.values }
  validates :nature, inclusion: { in: nature.values }
  validates :account, uniqueness: true
  # validates_presence_of :owner, if: :associate_account?

  delegate :currency, to: :journal, prefix: true

  scope :bank_accounts, -> { where(nature: 'bank_account') }
  scope :cash_boxes,    -> { where(nature: 'cash_box') }
  scope :associate_accounts, -> { where(nature: %w(associate_account owner_account)) }
  scope :with_pointing_work, -> { where(account_id: JournalEntryItem.select(:account_id).unpointed) }
  scope :pointables, -> { where(nature: %w(associate_account owner_account bank_account)) }

  # before create a bank account, this computes automati.ally code iban.
  before_validation do
    mode.lower! unless mode.blank?
    self.mode = self.class.mode.default_value if mode.blank?
    if currency.blank?
      if journal
        self.currency = journal_currency
      elsif eoc = Entity.of_company
        self.currency = eoc.currency
      end
    end
    if mode_iban?
      self.iban = iban.to_s.upper.gsub(/[^A-Z0-9]/, '')
    elsif mode_bban? && bank_code? && bank_agency_code? && bank_account_number? && bank_account_key
      self.iban = self.class.generate_iban(country, bank_code + bank_agency_code + bank_account_number + bank_account_key)
    end
    unless iban.blank?
      self.spaced_iban = iban.split(/(\w\w\w\w)/).delete_if(&:empty?).join(' ')
    end
  end

  # IBAN have to be checked before saved.
  validate do
    if journal
      unless currency == journal.currency
        errors.add(:journal, :currency_does_not_match, journal: journal.name)
      end
    end
    if bank_account?
      if mode_bban?
        unless country.blank?
          errors.add(:bank_account_key, :unvalid_bban) unless self.class.valid_bban?(country, attributes)
        end
      end
      unless iban.blank?
        errors.add(:iban, :invalid) unless self.class.valid_iban?(iban)
      end
    end
  end

  protect(on: :destroy) do
    used?
  end

  def used?
    deposits.any? || bank_statements.any? || outgoing_payment_modes.any? || incoming_payment_modes.any?
  end

  def formatted_bban(separator = ' ')
    [bank_code, bank_agency_code, bank_account_number, bank_account_key].join(separator)
  end

  # Checks if the BBAN is valid.
  def self.valid_bban?(country_code, options = {})
    case cc = country_code.lower.to_sym
    when :fr
      ban = (options['bank_code'].to_s.lower.tr(*BBAN_TRANSLATIONS[cc]).to_i * 89 + options['bank_agency_code'].to_s.lower.tr(*BBAN_TRANSLATIONS[cc]).to_i * 15 + options['bank_account_number'].to_s.lower.tr(*BBAN_TRANSLATIONS[cc]).to_i * 3)
      return (options['bank_account_key'].to_i + ban.modulo(97) - 97).zero?
    else
      raise ArgumentError, "Unknown country code #{country_code.inspect}"
    end
  end

  # Checks if the IBAN is valid.
  def self.valid_iban?(iban)
    iban = iban.to_s
    return false unless iban.length > 4
    str = iban[4..iban.length] + iban[0..1] + '00'

    # Test the iban key
    str.each_char do |c|
      str.gsub!(c, c.to_i(36).to_s) if c =~ /\D/
    end
    iban_key = 98 - (str.to_i.modulo 97)
    (iban_key.to_i == iban[2..3].to_i)
  end

  # Generates the IBAN key.
  def self.generate_iban(country_code, bban)
    iban = bban + country_code.upcase + '00'
    iban.each_char do |c|
      iban.gsub!(c, c.to_i(36).to_s) if c =~ /\D/
    end
    country_code + (98 - (iban.to_i.modulo 97)).to_s + bban
  end

  # Load default cashes (1 bank account and 1 cash box)
  def self.load_defaults
    [
      [:bank_account, :bank, :banks],
      [:cash_box, :cash, :cashes]
    ].each do |nature, journal_nature, account_usage|
      next if find_by(nature: nature)
      journal = Journal.find_by(nature: journal_nature)
      account = Account.find_or_import_from_nomenclature(account_usage)
      next unless journal && account
      create!(
        name: "enumerize.cash.nature.#{nature}".t,
        nature: nature.to_s,
        account: account,
        journal: journal
      )
    end
  end

  def pointable?
    bank_account? || associate_account?
  end

  def unpointed_journal_entry_items?
    pointable? && unpointed_journal_entry_items.any?
  end

  def monthly_sums(started_at, stopped_at, expr = 'debit - credit')
    account.journal_entry_items.between(started_at, stopped_at).group('EXTRACT(YEAR FROM printed_on)*100 + EXTRACT(MONTH FROM printed_on)').sum(expr).sort.each_with_object({}) do |pair, hash|
      hash[pair[0].to_i.to_s] = pair[1].to_d
      hash
    end
  end

  def next_reconciliation_letters
    Enumerator.new do |yielder|
      letter_column = "#{BankStatementItem.table_name}.letter"
      letter = 'A'
      loop do
        if bank_statements.joins(:items).where(letter_column => letter).blank?
          yielder << letter
        end
        letter = letter.succ
      end
    end
  end

  # Returns cash balance in the global currency
  def balance(at = Time.zone.now)
    closure = FinancialYear.last_closure || Date.civil(-1, 12, 31)
    closure += 1
    journal_entry_items.where(printed_on: closure..at.to_date).sum('real_debit - real_credit') || 0.0
  end
end
