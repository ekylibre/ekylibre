# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: journal_entry_items
#
#  absolute_credit           :decimal(19, 4)   default(0.0), not null
#  absolute_currency         :string           not null
#  absolute_debit            :decimal(19, 4)   default(0.0), not null
#  absolute_pretax_amount    :decimal(19, 4)   default(0.0), not null
#  account_id                :integer          not null
#  activity_budget_id        :integer
#  balance                   :decimal(19, 4)   default(0.0), not null
#  bank_statement_id         :integer
#  bank_statement_letter     :string
#  created_at                :datetime         not null
#  creator_id                :integer
#  credit                    :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_credit :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_debit  :decimal(19, 4)   default(0.0), not null
#  currency                  :string           not null
#  debit                     :decimal(19, 4)   default(0.0), not null
#  description               :text
#  entry_id                  :integer          not null
#  entry_number              :string           not null
#  financial_year_id         :integer          not null
#  id                        :integer          not null, primary key
#  journal_id                :integer          not null
#  letter                    :string
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  position                  :integer
#  pretax_amount             :decimal(19, 4)   default(0.0), not null
#  printed_on                :date             not null
#  real_balance              :decimal(19, 4)   default(0.0), not null
#  real_credit               :decimal(19, 4)   default(0.0), not null
#  real_currency             :string           not null
#  real_currency_rate        :decimal(19, 10)  default(0.0), not null
#  real_debit                :decimal(19, 4)   default(0.0), not null
#  real_pretax_amount        :decimal(19, 4)   default(0.0), not null
#  resource_id               :integer
#  resource_prism            :string
#  resource_type             :string
#  state                     :string           not null
#  tax_declaration_item_id   :integer
#  tax_id                    :integer
#  team_id                   :integer
#  updated_at                :datetime         not null
#  updater_id                :integer
#

# What are the differents columns:
#   * (credit|debit|balance) are in currency of the journal
#   * real_(credit|debit|balance) are in currency of the financial year
#   * absolute_(credit|debit|balance) are in currency of the company
#   * cumulated_absolute_(credit|debit) are in currency of the company too
class JournalEntryItem < Ekylibre::Record::Base
  attr_readonly :entry_id, :journal_id, :state
  refers_to :absolute_currency, class_name: 'Currency'
  refers_to :currency
  refers_to :real_currency, class_name: 'Currency'
  belongs_to :account
  belongs_to :activity_budget
  belongs_to :bank_statement
  belongs_to :entry, class_name: 'JournalEntry', inverse_of: :items
  belongs_to :financial_year
  belongs_to :journal, inverse_of: :entry_items
  belongs_to :resource, polymorphic: true
  belongs_to :tax
  belongs_to :tax_declaration_item, inverse_of: :journal_entry_items
  belongs_to :team

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absolute_credit, :absolute_debit, :absolute_pretax_amount, :balance, :credit, :cumulated_absolute_credit, :cumulated_absolute_debit, :debit, :pretax_amount, :real_balance, :real_credit, :real_debit, :real_pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :absolute_currency, :account, :currency, :entry, :financial_year, :journal, :real_currency, presence: true
  validates :bank_statement_letter, :letter, :resource_prism, :resource_type, length: { maximum: 500 }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :entry_number, :name, :state, presence: true, length: { maximum: 500 }
  validates :printed_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :real_currency_rate, presence: true, numericality: { greater_than: -1_000_000_000, less_than: 1_000_000_000 }
  # ]VALIDATORS]
  validates :absolute_currency, :currency, :real_currency, length: { allow_nil: true, maximum: 3 }
  validates :letter, length: { allow_nil: true, maximum: 10 }
  validates :state, length: { allow_nil: true, maximum: 30 }
  validates :debit, :credit, :real_debit, :real_credit, numericality: { greater_than_or_equal_to: 0 }
  validates :account, presence: true
  # validates :letter, uniqueness: { scope: :account_id }, if: Proc.new {|x| !x.letter.blank? }

  delegate :balanced?, to: :entry, prefix: true
  delegate :name, :number, to: :account, prefix: true
  delegate :entity_country, :expected_financial_year, to: :entry

  acts_as_list scope: :entry

  before_update  :uncumulate
  before_destroy :uncumulate
  after_destroy  :unmark

  scope :between, lambda { |started_at, stopped_at|
    where(printed_on: started_at..stopped_at)
  }
  scope :opened, -> { where.not(state: 'closed') }
  scope :unpointed, -> { where(bank_statement_letter: nil) }
  scope :pointed_by, lambda { |bank_statement|
    where('bank_statement_letter IS NOT NULL').where(bank_statement_id: bank_statement.id)
  }
  scope :pointed_by_with_letter, lambda { |bank_statement, letter|
    where(bank_statement_letter: letter).where(bank_statement_id: bank_statement.id)
  }

  state_machine :state, initial: :draft do
    state :draft
    state :confirmed
    state :closed
  end

  #
  before_validation do
    self.name = name.to_s[0..254]
    self.letter = nil if letter.blank?
    self.bank_statement_letter = nil if bank_statement_letter.blank?
    # computes the values depending on currency rate
    # for debit and credit.
    compute
    self.state = entry.state if entry
  end

  validate(on: :update) do
    old = old_record
    list = changed - %w[printed_on cumulated_absolute_debit cumulated_absolute_credit]
    if old.closed? && list.any?
      list.each do |attribute|
        if !entry.respond_to?(attribute) || (entry.send(attribute) != send(attribute))
          errors.add(attribute, :entry_has_been_already_validated)
        end
      end
    end
    # Forbids to change "manually" the letter. Use Account#mark/unmark.
    # if old.letter != self.letter and not (old.balanced_letter? and self.balanced_letter?)
    #   errors.add(:letter, :invalid)
    # end
  end

  #
  validate do
    # unless self.updateable?
    #   errors.add(:number, :closed_entry)
    #   return
    # end
    errors.add(:credit, :unvalid_amounts) if debit.nonzero? && credit.nonzero?
    errors.add(:real_credit, :unvalid_amounts) if real_debit.nonzero? && real_credit.nonzero?
    errors.add(:absolute_credit, :unvalid_amounts) if absolute_debit.nonzero? && absolute_credit.nonzero?
  end

  after_save do
    followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit + #{absolute_debit}, cumulated_absolute_credit = cumulated_absolute_credit + #{absolute_credit}")
  end

  before_destroy :clear_bank_statement_reconciliation

  protect do
    closed? || (entry && entry.protected_on_update?)
  end

  def compute
    self.debit       ||= 0
    self.credit      ||= 0
    self.real_debit  ||= 0
    self.real_credit ||= 0

    if entry
      self.entry_number = entry.number
      %i[financial_year_id printed_on journal_id currency
         absolute_currency real_currency real_currency_rate].each do |replicated|
        send("#{replicated}=", entry.send(replicated))
      end
      unless closed?
        self.debit  = real_debit * real_currency_rate
        self.credit = real_credit * real_currency_rate
        self.pretax_amount = real_pretax_amount * real_currency_rate
        if currency && Nomen::Currency.find(currency)
          precision = Nomen::Currency.find(currency).precision
          self.debit  = debit.round(precision)
          self.credit = credit.round(precision)
          self.pretax_amount = pretax_amount.round(precision)
        end
      end
    end
    self.absolute_currency = Preference[:currency]
    if absolute_currency == currency
      self.absolute_debit = debit
      self.absolute_credit = credit
      self.absolute_pretax_amount = pretax_amount
    elsif absolute_currency == real_currency
      self.absolute_debit = real_debit
      self.absolute_credit = real_credit
      self.absolute_pretax_amount = real_pretax_amount
    else
      # FIXME: We need to do something better when currencies don't match
      if currency.present? && (absolute_currency.present? || real_currency.present?)
        raise JournalEntry::IncompatibleCurrencies, "You cannot create an entry where the absolute currency (#{absolute_currency.inspect}) is not the real (#{real_currency.inspect}) or current one (#{currency.inspect})"
      end
    end
    self.cumulated_absolute_debit  = absolute_debit
    self.cumulated_absolute_credit = absolute_credit
    if previous
      self.cumulated_absolute_debit += previous.cumulated_absolute_debit
      self.cumulated_absolute_credit += previous.cumulated_absolute_credit
    end
    self.balance = debit - credit
    self.real_balance = real_debit - real_credit
  end

  def clear_bank_statement_reconciliation
    return unless bank_statement && bank_statement_letter
    bank_statement.items.where(letter: bank_statement_letter).update_all(letter: nil)
  end

  # Computes attribute for adding an item
  def self.attributes_for(name, account, amount, options = {})
    if name.size > 255
      omission = (options.delete(:omission) || '...').to_s
      name = name[0..254 - omission.size] + omission
    end
    credit = options.delete(:credit) ? true : false
    credit = !credit if amount < 0
    attributes = options.merge(name: name)
    attributes[:account_id] = account.is_a?(Integer) ? account : account.id
    attributes[:activity_budget_id] = options[:activity_budget].id if options[:activity_budget]
    attributes[:team_id] = options[:team].id if options[:team]
    attributes[:tax_id] = options[:tax].id if options[:tax]
    attributes[:real_pretax_amount] = attributes.delete(:pretax_amount) if attributes[:pretax_amount]
    attributes[:resource_prism] = attributes.delete(:as) if options[:as]
    attributes[:letter] = attributes.delete(:letter) if options[:letter]
    if credit
      attributes[:real_credit] = amount.abs
      attributes[:real_debit]  = 0.0
    else
      attributes[:real_credit] = 0.0
      attributes[:real_debit]  = amount.abs
    end
    attributes
  end

  def self.new_for(name, account, amount, options = {})
    new(attributes_for(name, account, amount, options))
  end

  # Prints human name of current state
  def state_label
    JournalEntry.tc("states.#{state}")
  end

  # Updates the amounts to the debit and the credit
  # for the matching entry.
  def update_entry
    entry.refresh
  end

  # Cancel old values if specific columns have been updated
  def uncumulate
    old = old_record
    if absolute_debit != old.absolute_debit || absolute_credit != old.absolute_credit || printed_on != old.printed_on
      # self.cumulated_absolute_debit  -= old.absolute_debit
      # self.cumulated_absolute_credit -= old.absolute_credit
      old.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit - #{old.absolute_debit}, cumulated_absolute_credit = cumulated_absolute_credit - #{old.absolute_debit}")
    end
  end

  # Unmark all the journal entry items with the same mark in the same account
  def unmark
    account.unmark(letter) if letter.present?
  end

  # Returns the previous item
  def previous
    return nil unless account
    if new_record?
      account.journal_entry_items.order(printed_on: :desc, id: :desc).where('printed_on <= ?', printed_on).limit(1).first
    else
      account.journal_entry_items.order(printed_on: :desc, id: :desc).where('(printed_on = ? AND id < ?) OR printed_on < ?', printed_on, id, printed_on).limit(1).first
    end
  end

  # Returns following items
  def followings
    return self.class.none unless account
    if new_record?
      account.journal_entry_items.where('printed_on > ?', printed_on)
    else
      account.journal_entry_items.where('(printed_on = ? AND id > ?) OR printed_on > ?', printed_on, id, printed_on)
    end
  end

  # Returns the balance as cumulated_absolute_debit - cumulated_absolute_credit
  def cumulated_absolute_balance
    (self.cumulated_absolute_debit - self.cumulated_absolute_credit)
  end

  #   # this method allows to lock the entry_item.
  #   def close
  #     self.update_column(:closed, true)
  #   end

  #   def reopen
  #     self.update_column(:closed, false)
  #   end

  # Check if the current letter is balanced with all entry items with the same letter
  def balanced_letter?
    return true if letter.blank?
    account.balanced_letter?(letter)
  end

  # this method allows to fix a display color if the entry_item is in draft mode.
  def mode
    mode = ''
    mode += 'warning' if draft?
    mode
  end

  #
  def resource
    if entry
      entry.resource_type
    else
      :none.tl
    end
  end

  # get link item corresponding to charge or product line in purchase or sale from vat item
  def vat_item_to_product_account
    product_journal_entry_item = entry.items.find_by(resource_id: resource_id, resource_prism: 'item_product')
    if product_journal_entry_item
      a = Account.where(id: product_journal_entry_item.account_id).first
      return a.label if a
    end
  end

  # get link item corresponding to vat line from product item
  def product_item_to_tax_label
    vat_journal_entry_item = entry.items.find_by(resource_id: resource_id, resource_prism: 'item_tax') # where.not(id: self.id).
    if vat_journal_entry_item && vat_journal_entry_item.id != id
      t = Tax.find(vat_journal_entry_item.tax_id)
      return t.name if t
    end
  end

  # This method returns the name of journal which the entries are saved.
  def journal_name
    if entry
      entry.journal.name
    else
      :none.tl
    end
  end

  # this method:allows to fix a display color if the entry containing the entry_item is balanced or not.
  def balanced_entry
    (entry.balanced? ? 'balanced' : 'unbalanced')
  end

  # this method creates a next entry_item with an initialized value matching to the previous entry.
  def next(balance)
    entry_item = JournalEntryItem.new
    if balance > 0
      entry_item.real_credit = balance.abs
    elsif balance < 0
      entry_item.real_debit = balance.abs
    end
    entry_item
  end

  def third_party
    return unless account
    third_parties = Entity.uniq.where('client_account_id = ? OR supplier_account_id = ? OR employee_account_id = ?', account.id, account.id, account.id)
    third_parties.take if third_parties.count == 1
  end
end
