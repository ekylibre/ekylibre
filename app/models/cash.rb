# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  BBAN_TRANSLATIONS = {
    :fr => ["abcdefghijklmonpqrstuvwxyz", "12345678912345678923456789"]
  }
  # attr_accessible :name, :nature, :mode, :iban, :bank_identifier_code, :bank_account_key, :bank_name, :bank_code, :bank_agency_code, :bank_account_number, :bank_agency_address, :account_id, :journal_id, :country, :currency
  attr_readonly :nature
  attr_readonly :currency, if: :used?
  belongs_to :account
  belongs_to :container, class_name: 'Product'
  belongs_to :journal
  belongs_to :owner, class_name: 'Entity'
  has_many :active_sessions, -> { actives }, class_name: "CashSession"
  has_many :bank_statements, dependent: :destroy
  has_many :cashes
  has_many :deposits
  has_many :journal_entry_items, through: :account
  has_many :outgoing_payment_modes
  has_many :incoming_payment_modes
  has_many :sessions, class_name: "CashSession"
  has_many :unpointed_journal_entry_items, -> { where(bank_statement_id: nil) }, through: :account, source: :journal_entry_items
  has_one :last_bank_statement, -> { order("stopped_at DESC") }, class_name: "BankStatement"

  enumerize :nature, in: [:bank_account, :cash_box, :associated_account], default: :bank_account, predicates: true
  enumerize :mode, in: [:iban, :bban], default: :iban, predicates: {prefix: true}
  # enumerize :currency, in: Nomen::Currencies.all

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :last_number, allow_nil: true, only_integer: true
  validates_presence_of :account, :currency, :journal, :mode, :name, :nature
  #]VALIDATORS]
  validates_length_of :country, allow_blank: true, maximum: 2
  validates_length_of :currency, allow_blank: true, maximum: 3
  validates_length_of :bank_identifier_code, allow_blank: true, maximum: 11
  validates_length_of :nature, allow_blank: true, maximum: 20
  validates_length_of :iban, allow_blank: true, maximum: 34
  validates_length_of :spaced_iban, allow_blank: true, maximum: 42
  validates_length_of :bank_name, allow_blank: true, maximum: 50
  validates_inclusion_of :mode, in: self.mode.values
  validates_inclusion_of :nature, in: self.nature.values
  validates_uniqueness_of :account_id

  delegate :currency, to: :journal, prefix: true

  scope :bank_accounts, -> { where(nature: "bank_account") }
  scope :cash_boxes,    -> { where(nature: "cash_box") }
  scope :associated_accounts,    -> { where(nature: "associated_account") }

  # before create a bank account, this computes automati.ally code iban.
  before_validation do
    self.mode.lower! if !self.mode.blank?
    self.mode = self.class.mode.default_value if self.mode.blank?
    if self.currency.blank?
      if self.journal
        self.currency = self.journal_currency
      elsif eoc = Entity.of_company
        self.currency = eoc.currency
      end
    end
    if self.mode_iban?
      self.iban = self.iban.to_s.upper.gsub(/[^A-Z0-9]/, '')
    elsif self.mode_bban? and self.bank_code? and self.bank_agency_code? and self.bank_account_number? and self.bank_account_key
      self.iban = self.class.generate_iban(self.country, self.bank_code + self.bank_agency_code + self.bank_account_number + self.bank_account_key)
    end
    unless self.iban.blank?
      self.spaced_iban = self.iban.split(/(\w\w\w\w)/).delete_if{|k| k.empty?}.join(" ")
    end
  end

  # IBAN have to be checked before saved.
  validate do
    if self.journal
      unless self.currency == self.journal.currency
        errors.add(:journal, :currency_does_not_match, journal: self.journal.name)
      end
    end
    if self.bank_account?
      if self.mode_bban?
        unless self.country.blank?
          errors.add(:bank_account_key, :unvalid_bban) unless self.class.valid_bban?(self.country, self.attributes)
        end
      end
      unless self.iban.blank?
        errors.add(:iban, :invalid) unless self.class.valid_iban?(self.iban)
      end
    end
  end

  protect(on: :destroy) do
    self.used?
  end

  def used?
    self.deposits.any? or self.bank_statements.any? or self.outgoing_payment_modes.any? or self.incoming_payment_modes.any?
  end

  def formatted_bban(separator = " ")
    return [self.bank_code, self.bank_agency_code, self.bank_account_number, self.bank_account_key].join(separator)
  end

  # Checks if the BBAN is valid.
  def self.valid_bban?(country_code, options={})
    case cc = country_code.lower.to_sym
    when :fr
      ban = (options["bank_code"].to_s.lower.tr(*BBAN_TRANSLATIONS[cc]).to_i*89+
             options["bank_agency_code"].to_s.lower.tr(*BBAN_TRANSLATIONS[cc]).to_i*15+
             options["bank_account_number"].to_s.lower.tr(*BBAN_TRANSLATIONS[cc]).to_i*3)
      return (options["bank_account_key"].to_i + ban.modulo(97) - 97).zero?
    else
      raise ArgumentError, "Unknown country code #{country_code.inspect}"
    end
  end

  # Checks if the IBAN is valid.
  def self.valid_iban?(iban)
    iban = iban.to_s
    return false unless iban.length > 4
    str = iban[4..iban.length] + iban[0..1] + "00"

    # Test the iban key
    str.each_char do |c|
      if c=~/\D/
        str.gsub!(c, c.to_i(36).to_s)
      end
    end
    iban_key = 98 - (str.to_i.modulo 97)
    return (iban_key.to_i == iban[2..3].to_i)
  end

  # Generates the IBAN key.
  def self.generate_iban(country_code, bban)
    iban = bban + country_code.upcase + "00"
    iban.each_char do |c|
      if c =~ /\D/
        iban.gsub!(c, c.to_i(36).to_s)
      end
    end
    return country_code + (98 - (iban.to_i.modulo 97)).to_s + bban
  end

  def monthly_sums(started_at, stopped_at, expr = "debit - credit")
    self.account.journal_entry_items.between(started_at, stopped_at).group("EXTRACT(YEAR FROM printed_on)*100 + EXTRACT(MONTH FROM printed_on)").sum(expr).sort.inject({}) do |hash, pair|
      hash[pair[0].to_i.to_s] = pair[1].to_d
      hash
    end
  end


  # Returns cash balance in the global currency
  def balance(at = Time.now)
    closure = FinancialYear.last_closure || Date.civil(-1, 12, 31)
    closure += 1
    return self.journal_entry_items.where(printed_on: closure..at.to_date).sum("debit - credit") || 0.0
  end

end

