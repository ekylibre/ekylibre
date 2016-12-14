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
# == Table: journal_entries
#
#  absolute_credit    :decimal(19, 4)   default(0.0), not null
#  absolute_currency  :string           not null
#  absolute_debit     :decimal(19, 4)   default(0.0), not null
#  balance            :decimal(19, 4)   default(0.0), not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  credit             :decimal(19, 4)   default(0.0), not null
#  currency           :string           not null
#  debit              :decimal(19, 4)   default(0.0), not null
#  financial_year_id  :integer
#  id                 :integer          not null, primary key
#  journal_id         :integer          not null
#  lock_version       :integer          default(0), not null
#  number             :string           not null
#  printed_on         :date             not null
#  real_balance       :decimal(19, 4)   default(0.0), not null
#  real_credit        :decimal(19, 4)   default(0.0), not null
#  real_currency      :string           not null
#  real_currency_rate :decimal(19, 10)  default(0.0), not null
#  real_debit         :decimal(19, 4)   default(0.0), not null
#  resource_id        :integer
#  resource_prism     :string
#  resource_type      :string
#  state              :string           not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#

# There is 3 types of set of values (debit, credit...). These types
# corresponds to the 3 currency we always add in accountancy:
#  - *          in journal currency
#  - real_*     in financial year currency
#  - absolute_* in global currency (the same as current financial year's theoretically)
class JournalEntry < Ekylibre::Record::Base
  class IncompatibleCurrencies < StandardError; end
  include Attachable
  attr_readonly :journal_id
  refers_to :currency
  refers_to :real_currency, class_name: 'Currency'
  refers_to :absolute_currency, class_name: 'Currency'
  belongs_to :financial_year
  belongs_to :journal, inverse_of: :entries
  belongs_to :resource, polymorphic: true
  has_many :affairs, dependent: :nullify
  has_many :fixed_asset_depreciations, dependent: :nullify
  has_many :useful_items, -> { where('balance != ?', 0.0) }, foreign_key: :entry_id, class_name: 'JournalEntryItem'
  has_many :items, foreign_key: :entry_id, dependent: :delete_all, class_name: 'JournalEntryItem', inverse_of: :entry
  has_many :outgoing_payments, dependent: :nullify
  has_many :incoming_payments, dependent: :nullify
  has_many :purchases, dependent: :nullify
  has_many :sales, dependent: :nullify
  has_one :financial_year_as_last, foreign_key: :last_journal_entry_id, class_name: 'FinancialYear', dependent: :nullify
  has_many :bank_statements, through: :useful_items
  accepts_nested_attributes_for :items
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absolute_credit, :absolute_debit, :balance, :credit, :debit, :real_balance, :real_credit, :real_debit, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :absolute_currency, :currency, :journal, :real_currency, presence: true
  validates :number, :state, presence: true, length: { maximum: 500 }
  validates :printed_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :real_currency_rate, presence: true, numericality: { greater_than: -1_000_000_000, less_than: 1_000_000_000 }
  validates :resource_prism, :resource_type, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :absolute_currency, :currency, :real_currency, length: { allow_nil: true, maximum: 3 }
  validates :state, length: { allow_nil: true, maximum: 30 }
  validates :real_currency, presence: true
  validates :number, format: { with: /\A[\dA-Z]+\z/ }
  validates :real_currency_rate, numericality: { greater_than: 0 }
  validates :number, uniqueness: { scope: [:journal_id, :financial_year_id] }

  accepts_nested_attributes_for :items

  scope :between, lambda { |started_on, stopped_on|
    where(printed_on: started_on..stopped_on)
  }

  state_machine :state, initial: :draft do
    state :draft
    state :confirmed
    state :closed
    event :confirm do
      transition draft: :confirmed, if: :balanced?
    end
    event :close do
      transition confirmed: :closed, if: :balanced?
    end
    #     event :reopen do
    #       transition :closed => :confirmed
    #     end
  end

  # Build an SQL condition based on options which should contains acceptable states
  def self.state_condition(states = {}, table_name = nil)
    table = table_name || self.table_name
    states = {} unless states.is_a? Hash
    if states.empty?
      return JournalEntry.connection.quoted_false
    else
      return "#{table}.state IN (#{states.collect { |s, _v| JournalEntry.connection.quote(s) }.join(',')})"
    end
  end

  # Build an SQL condition based on options which should contains acceptable states
  def self.journal_condition(journals = {}, table_name = nil)
    table = table_name || self.table_name
    journals = {} unless journals.is_a? Hash
    if journals.empty?
      return JournalEntry.connection.quoted_false
    else
      return "#{table}.journal_id IN (#{journals.collect { |s, _v| JournalEntry.connection.quote(s.to_i) }.join(',')})"
    end
  end

  # Build a condition for filter journal entries on period
  def self.period_condition(period, started_on, stopped_on, table_name = nil)
    table = table_name || self.table_name
    if period.to_s == 'all'
      return connection.quoted_true
    else
      conditions = []
      started_on, stopped_on = period.to_s.split('_')[0..1] unless period.to_s == 'interval'
      if started_on.present? && (started_on.is_a?(Date) || started_on =~ /^\d\d\d\d\-\d\d\-\d\d$/)
        conditions << "#{table}.printed_on >= #{connection.quote(started_on.to_date)}"
      end
      if stopped_on.present? && (stopped_on.is_a?(Date) || stopped_on =~ /^\d\d\d\d\-\d\d\-\d\d$/)
        conditions << "#{table}.printed_on <= #{connection.quote(stopped_on.to_date)}"
      end
      return connection.quoted_false if conditions.empty?
      return '(' + conditions.join(' AND ') + ')'
    end
  end

  # Returns states names
  def self.states
    state_machine.states.collect(&:name)
  end

  before_validation on: :create do
    self.state ||= :draft
  end

  before_validation do
    self.resource_type = resource.class.base_class.name if resource
    self.real_currency = journal.currency if journal
    if printed_on? && (self.financial_year = FinancialYear.at(printed_on))
      self.currency = financial_year.currency
    end
    if real_currency && financial_year
      if real_currency == financial_year.currency
        self.real_currency_rate = 1
      else
        # TODO: Find a better way to manage currency rates!
        # raise self.financial_year.inspect if I18n.currencies(self.financial_year.currency).nil?
        if real_currency_rate.blank? || real_currency_rate.zero?
          self.real_currency_rate = I18n.currency_rate(real_currency, currency)
        end
      end
    else
      self.real_currency_rate = 1
    end
    self.real_debit   = items.sum(:real_debit)
    self.real_credit  = items.sum(:real_credit)
    self.real_balance = real_debit - real_credit

    self.debit   = items.sum(:debit)
    self.credit  = items.sum(:credit)

    self.balance = debit - credit

    if real_balance.zero? && !balance.zero?
      error_sum = balance * 100
      column = if error_sum > 0
                 :credit
               else
                 :debit
               end

      error_sum = error_sum.abs

      even_items = items.select { |item| !item.send(column).zero? }
      proratas = even_items.map { |item| [item, item.send(column) / send(column)] }
      proratas.reduce(error_sum) do |left, item|
        error_to_update = [(error_sum * item[1]).ceil / 100.to_f, left].min
        item[0].update_columns(column => item[0].send(column) + error_to_update)

        left - error_to_update * 100
      end

      self.debit   = items.sum(:debit)
      self.credit  = items.sum(:credit)

      self.balance = debit - credit
    end

    self.absolute_currency = Preference[:currency]
    if absolute_currency == currency
      self.absolute_debit = debit
      self.absolute_credit = credit
    elsif absolute_currency == real_currency
      self.absolute_debit = real_debit
      self.absolute_credit = real_credit
    else
      # FIXME: We need to do something better when currencies don't match
      if currency? && (absolute_currency? || real_currency?)
        raise IncompatibleCurrencies, "You cannot create an entry where the absolute currency (#{absolute_currency.inspect}) is not the real (#{real_currency.inspect}) or current one (#{currency.inspect})"
      end
    end
    if number.present?
      number.upcase!
    elsif journal
      self.number ||= journal.next_number
    end
  end

  validate(on: :update) do
    old = self.class.find(id)
    errors.add(:number, :entry_has_been_already_validated) if old.closed?
  end

  #
  validate do
    # TODO: Validates number has journal's code as prefix
    if printed_on
      if journal
        errors.add(:printed_on, :closed_journal, journal: journal.name, closed_on: ::I18n.localize(journal.closed_on)) if printed_on <= journal.closed_on
      end
      unless financial_year
        errors.add(:printed_on, :out_of_existing_financial_year)
      end
    end
  end

  after_save do
    JournalEntryItem.where(entry_id: id).update_all(state: self.state, journal_id: journal_id, financial_year_id: financial_year_id, printed_on: printed_on, entry_number: self.number, real_currency: real_currency, real_currency_rate: real_currency_rate)
  end

  before_destroy do
    items.each(&:clear_bank_statement_reconciliation)
  end

  protect do
    printed_on <= journal.closed_on || old_record.closed?
  end

  # A journal generated by a resource is not editable!
  def editable?
    resource.nil?
  end

  def self.state_label(state)
    tc('states.' + state.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_label(self.state)
  end

  def bank_statement_number
    bank_statements.first.number if bank_statements.first
  end

  # determines if the entry is balanced or not.
  def balanced?
    balance.zero? # and self.items.count > 0
  end

  # this method computes the debit and the credit of the entry.
  def refresh
    reload
    save!
  end

  # Add a entry which cancel the entry
  # Create counter-entry_items
  def cancel
    reconcilable_accounts = []
    entry = self.class.new(journal: journal, resource: resource, real_currency: real_currency, real_currency_rate: real_currency_rate, printed_on: printed_on)
    ActiveRecord::Base.transaction do
      entry.save!
      for item in useful_items
        entry.send(:add!, tc(:entry_cancel, number: self.number, name: item.name), item.account, (item.debit - item.credit).abs, credit: (item.debit > 0))
        reconcilable_accounts << item.account if item.account.reconcilable? && !reconcilable_accounts.include?(item.account)
      end
    end
    # Mark accounts
    for account in reconcilable_accounts
      account.mark_entries(self, entry)
    end
    entry
  end

  def save_with_items(entry_items)
    ActiveRecord::Base.transaction do
      saved = save

      if saved
        # Remove removed items and keep existings
        items.where.not(id: entry_items.map { |i| i[:id] }).find_each(&:destroy)

        entry_items.each_with_index do |entry_item, _index|
          item = items.detect { |i| i.id == entry_item[:id].to_i }
          if item
            item.attributes = entry_item.except(:id)
          else
            item = items.build(entry_item.except(:id))
          end
          saved = false unless item.save
        end
        if saved
          reload
          unless items.any?
            errors.add(:items, :empty)
            saved = false
          end
          unless balanced?
            errors.add(:debit, :unbalanced)
            saved = false
          end
        end
        if saved
          return true
        else
          raise ActiveRecord::Rollback
        end
      end
    end
    false
  end

  # Adds an entry_item with the minimum informations. It computes debit and credit with the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example:
  #   entry.add_debit("blabla", account, -65) # will put +65 in +credit+ column
  def add_debit(name, account, amount, options = {})
    add!(name, account, amount, options)
  end

  #
  def add_credit(name, account, amount, options = {})
    add!(name, account, amount, options.merge(credit: true))
  end

  private

  #
  def add!(name, account, amount, options = {})
    # return if amount == 0
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

    if credit
      attributes[:real_credit] = amount.abs
      attributes[:real_debit]  = 0.0
    else
      attributes[:real_credit] = 0.0
      attributes[:real_debit]  = amount.abs
    end
    e = items.create!(attributes)
    e
  end
end
