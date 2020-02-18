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
# == Table: cashes
#
#  bank_account_holder_name          :string
#  bank_account_key                  :string
#  bank_account_number               :string
#  bank_agency_address               :text
#  bank_agency_code                  :string
#  bank_code                         :string
#  bank_identifier_code              :string
#  bank_name                         :string
#  by_default                        :boolean          default(FALSE)
#  container_id                      :integer
#  country                           :string
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  currency                          :string           not null
#  custom_fields                     :jsonb
#  enable_bookkeep_bank_item_details :boolean          default(FALSE)
#  iban                              :string
#  id                                :integer          not null, primary key
#  journal_id                        :integer          not null
#  last_number                       :integer
#  lock_version                      :integer          default(0), not null
#  main_account_id                   :integer          not null
#  mode                              :string           default("iban"), not null
#  name                              :string           not null
#  nature                            :string           default("bank_account"), not null
#  owner_id                          :integer
#  spaced_iban                       :string
#  suspend_until_reconciliation      :boolean          default(FALSE), not null
#  suspense_account_id               :integer
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#

class Cash < Ekylibre::Record::Base
  include Attachable
  include Customizable
  BBAN_TRANSLATIONS = {
    fr: %w[abcdefghijklmonpqrstuvwxyz 12345678912345678923456789]
  }.freeze
  attr_readonly :nature
  attr_readonly :currency, if: :used?
  refers_to :country
  refers_to :currency
  belongs_to :container, class_name: 'Product'
  belongs_to :journal
  belongs_to :main_account, class_name: 'Account'
  belongs_to :owner, class_name: 'Entity'
  belongs_to :suspense_account, class_name: 'Account'
  has_many :active_sessions, -> { actives }, class_name: 'CashSession'
  has_many :bank_statements, dependent: :destroy
  has_many :deposits
  has_many :main_journal_entry_items, through: :main_account, source: :journal_entry_items
  has_many :suspended_journal_entry_items, through: :suspense_account, source: :journal_entry_items
  has_many :outgoing_payment_modes
  has_many :incoming_payment_modes
  has_many :sessions, class_name: 'CashSession'
  has_many :unpointed_main_journal_entry_items, -> { unpointed },
           through: :main_account, source: :journal_entry_items
  has_many :unpointed_suspended_journal_entry_items, -> { unpointed.where.not(entry_id: BankStatement.where('journal_entry_id IS NOT NULL').select(:journal_entry_id)) },
           through: :suspense_account, source: :journal_entry_items
  has_many :unpointed_lines_suspended_journal_entry_items, -> { unpointed.where.not(entry_id: BankStatementItem.where('journal_entry_id IS NOT NULL').select(:journal_entry_id)) },
                    through: :suspense_account, source: :journal_entry_items
  has_one :last_bank_statement, -> { order(stopped_on: :desc) }, class_name: 'BankStatement'

  enumerize :nature, in: %i[bank_account cash_box associate_account], default: :bank_account, predicates: true
  enumerize :mode, in: %i[iban bban], default: :iban, predicates: { prefix: true }

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :bank_account_holder_name, :bank_account_key, :bank_account_number, :bank_agency_code, :bank_code, :bank_identifier_code, :bank_name, :iban, :spaced_iban, length: { maximum: 500 }, allow_blank: true
  validates :bank_agency_address, length: { maximum: 500_000 }, allow_blank: true
  validates :by_default, :enable_bookkeep_bank_item_details, inclusion: { in: [true, false] }, allow_blank: true
  validates :currency, :journal, :main_account, :mode, :nature, presence: true
  validates :last_number, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :suspend_until_reconciliation, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :country, length: { allow_blank: true, maximum: 2 }
  validates :currency, length: { allow_blank: true, maximum: 3 }
  validates :bank_identifier_code, length: { allow_blank: true, maximum: 11 }
  validates :nature, length: { allow_blank: true, maximum: 20 }
  validates :iban, iban: true, allow_blank: true, if: :bank_account?
  validates :spaced_iban, length: { allow_blank: true, maximum: 42 }
  validates :bank_name, length: { allow_blank: true, maximum: 50 }
  validates :mode, inclusion: { in: mode.values }
  validates :nature, inclusion: { in: nature.values }
  validates :main_account, uniqueness: { allow_blank: true }
  validates :suspense_account, uniqueness: { allow_blank: true }, presence: { if: :suspend_until_reconciliation }

  delegate :currency, to: :journal, prefix: true

  scope :bank_accounts, -> { where(nature: 'bank_account') }
  scope :cash_boxes,    -> { where(nature: 'cash_box') }
  scope :associate_accounts, -> { where(nature: %w[associate_account owner_account]) }
  scope :with_pointing_work, -> { where('(suspend_until_reconciliation AND suspense_account_id in (?)) OR (NOT suspend_until_reconciliation AND main_account_id IN (?))', JournalEntryItem.select(:suspense_account_id).unpointed, JournalEntryItem.select(:main_account_id).unpointed) }
  scope :pointables, -> { where(nature: %w[associate_account owner_account bank_account]) }
  scope :with_deposit, -> { where(id: IncomingPaymentMode.where(with_deposit: true).select(:cash_id)) }

  # before create a bank account, this computes automati.ally code iban.
  before_validation do
    self.mode = mode.to_s.lower if mode.present?
    self.mode = self.class.mode.default_value if mode.blank?
    self.suspend_until_reconciliation = false unless bank_account?
    unless bank_account_holder_name.nil?
      self.bank_account_holder_name = I18n.transliterate(bank_account_holder_name)
    end
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
    if iban.present?
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
      if mode_bban? && country?
        errors.add(:bank_account_key, :unvalid_bban) unless self.class.valid_bban?(country, attributes)
      end
      if suspend_until_reconciliation && suspense_account
        if suspense_account == main_account
          errors.add(:suspense_account, :different_of_main_account, account: main_account.number)
        end
      end
    end
  end

  protect(on: :destroy) do
    used?
  end

  def journal_entry_items
    suspend_until_reconciliation ? suspended_journal_entry_items : main_journal_entry_items
  end

  def unpointed_journal_entry_items
    if suspend_until_reconciliation
      if enable_bookkeep_bank_item_details
        unpointed_lines_suspended_journal_entry_items
      else
        unpointed_suspended_journal_entry_items
      end
    else
      unpointed_main_journal_entry_items
    end
  end

  def account_id
    suspend_until_reconciliation ? suspense_account_id : main_account_id
  end

  def account_id=(id)
    if suspend_until_reconciliation
      self.suspense_account_id = id
    else
      self.main_account_id = id
    end
  end

  def account
    suspend_until_reconciliation ? suspense_account : main_account
  end

  def account=(record)
    if suspend_until_reconciliation
      self.suspense_account = record
    else
      self.main_account = record
    end
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
      (options['bank_account_key'].to_i + ban.modulo(97) - 97).zero?
    else
      raise ArgumentError, "Unknown country code #{country_code.inspect}"
    end
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
  def self.load_defaults(**_options)
    [
      %i[bank_account bank banks],
      %i[cash_box cash cashes]
    ].each do |nature, journal_nature, account_usage|
      next if find_by(nature: nature)
      journal = Journal.find_by(nature: journal_nature)
      account = Account.find_or_import_from_nomenclature(account_usage)
      next unless journal && account
      create!(
        name: "enumerize.cash.nature.#{nature}".t,
        nature: nature.to_s,
        main_account: account,
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
    main_account.journal_entry_items.between(started_at, stopped_at).group('EXTRACT(YEAR FROM printed_on)*100 + EXTRACT(MONTH FROM printed_on)').sum(expr).sort.each_with_object({}) do |pair, hash|
      hash[pair[0].to_i.to_s] = pair[1].to_d
      hash
    end
  end

  def next_reconciliation_letter
    item = BankStatementItem.where('LENGTH(TRIM(letter)) > 0').order('LENGTH(letter) DESC, letter DESC').first
    item ? item.letter.succ : 'A'
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

  # Return last entry date
  def last_journal_entry
    main_journal_entry_items.reorder(printed_on: :desc).first
  end

  # Return last date of bank_item from bank statements link to current cash
  def last_bank_statement_stopped_on
    if last_bank_statement
      last_bank_statement.stopped_on
    else
      nil
    end
  end

  # Returns (real) main account cash balance in the global currency
  def balance(at = Time.zone.now)
    if at == Time.zone.now
      main_journal_entry_items.sum('real_debit - real_credit') || 0.0
    else
      closure = FinancialYear.last_closure || Date.civil(-1, 12, 31)
      closure += 1
      main_journal_entry_items.where(printed_on: closure..at.to_date).sum('real_debit - real_credit') || 0.0
    end
  end

  # Returns (theoric) suspense account cash balance in the global currency
  def suspended_balance(_at = Time.zone.now)
    suspended_journal_entry_items.sum('real_debit - real_credit') || 0.0
  end

  def letter_items(statement_items, journal_entry_items)
    new_letter = next_reconciliation_letter
    return false if (journal_entry_items + statement_items).length.zero?

    bank_statement_id = statement_items.map(&:bank_statement_id).uniq.first
    statement_entries = JournalEntryItem.where(resource: statement_items)
    to_letter = journal_entry_items + statement_entries
    suspense_account.mark(to_letter) if suspend_until_reconciliation

    saved = true
    saved &&= statement_items.update_all(letter: new_letter)
    saved &&= journal_entry_items.update_all(
      bank_statement_letter: new_letter,
      bank_statement_id: bank_statement_id
    )

    saved && new_letter
  end
end
