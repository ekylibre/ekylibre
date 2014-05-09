# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: financial_years
#
#  closed                :boolean          not null
#  code                  :string(20)       not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string(3)        not null
#  currency_precision    :integer
#  id                    :integer          not null, primary key
#  last_journal_entry_id :integer
#  lock_version          :integer          default(0), not null
#  started_at            :datetime         not null
#  stopped_at            :datetime         not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#


class FinancialYear < Ekylibre::Record::Base
  attr_readonly :currency
  belongs_to :last_journal_entry, class_name: "JournalEntry"
  has_many :account_balances, class_name: "AccountBalance", foreign_key: :financial_year_id, dependent: :delete_all
  has_many :financial_asset_depreciations
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :currency_precision, allow_nil: true, only_integer: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :code, allow_nil: true, maximum: 20
  validates_inclusion_of :closed, in: [true, false]
  validates_presence_of :code, :currency, :started_at, :stopped_at
  #]VALIDATORS]
  validates_uniqueness_of :code
  validates_presence_of :currency

  # This order must be the natural order
  # It permit to find the first and the last financial year
  scope :currents,  -> { where(closed: false).reorder(:started_at) }
  scope :closables, -> { where(closed: false).where("stopped_at < ?", Time.now).reorder(:started_at).limit(1) }

  # Find or create if possible the requested financial year for the searched date
  def self.at(searched_at = Time.now)
    year = self.where("? BETWEEN started_at AND stopped_at", searched_at).order(started_at: :desc).first
    unless year
      # First
      first = self.reorder(:started_at).first
      unless first
        started_at = Date.today
        first = self.create!(started_at: started_at, stopped_at: (started_at >> 12).end_of_month)
      end
      return nil if first.started_at > searched_at

      # Next years
      other = first
      while searched_at > other.stopped_at
        other = other.find_or_create_next
      end
      return other
    end
    return year
  end

  def self.current
    self.currents.first
  end

  def self.closable
    self.closables.first
  end

  before_validation do
    self.currency ||= Preference[:currency]
    self.started_at = self.started_at.to_datetime.beginning_of_day if self.started_at
    self.stopped_at = self.started_at + 1.year if self.stopped_at.blank? and self.started_at
    self.stopped_at = self.stopped_at.to_datetime.end_of_month unless self.stopped_at.blank?
    if self.started_at and self.stopped_at and code.blank?
      self.code = self.default_code
    end
    self.code.upper!
    while self.class.where(code: self.code).where.not(id: self.id || 0).any? do
      self.code.succ!
    end
  end

  validate do
    unless self.stopped_at.blank? or self.started_at.blank?
      errors.add(:stopped_at, :end_of_month) unless self.stopped_at == self.stopped_at.end_of_month
      errors.add(:stopped_at, :posterior, to: ::I18n.localize(self.started_at)) unless self.started_at < self.stopped_at
      # If some financial years are already present
      id = self.id || 0
      if self.class.where.not(id: id).any?
        errors.add(:started_at, :overlap) if self.class.where("id != ? AND ? BETWEEN started_at AND stopped_at", id, self.started_at).first
        errors.add(:stopped_at, :overlap) if self.class.where("id != ? AND ? BETWEEN started_at AND stopped_at", id, self.stopped_at).first
      end
    end
  end

  def journal_entries(conditions=nil)
    JournalEntry.where(printed_at: self.started_at..self.stopped_at).where(conditions.nil? ? true : conditions)
  end

  def name
    self.code
  end

  def default_code
    tc("code." + (self.started_at.year != self.stopped_at.year ? "double" : "single"), first_year: self.started_at.year, second_year: self.stopped_at.year)
  end

  # tests if the financial_year can be closed.
  def closable?(noticed_at=nil)
    noticed_at ||= Date.today
    return false if self.closed
    if previous = self.previous
      return false if self.previous.closable?
    end
    return false unless self.journal_entries("debit != credit").empty?
    return (self.stopped_at < noticed_at)
  end


  def closures(noticed_at=nil)
    noticed_at ||= Date.today
    array, first_year = [], self.class.order("started_at").first
    if (first_year.nil? or first_year == self) and self.class.count <= 1
      date = self.started_at.end_of_month
      while date < noticed_at
        array << date
        date = (date+1).end_of_month
      end
    else
      array << self.stopped_at
    end
    return array
  end


  # When a financial year is closed,.all the matching journals are closed too.
  def close(to_close_at=nil, options={})
    return false unless self.closable?

    to_close_at ||= self.stopped_at

    ActiveRecord::Base.transaction do
      # Close.all journals to the
      for journal in Journal.where("closed_at < ?", to_close_at)
        raise false unless journal.close(to_close_at)
      end

      # Close year
      self.update_attributes(:stopped_at => to_close_at, :closed => true)

      # Compute balance of closed year
      self.compute_balances!

      # Create first entry of the new year
      if renew_journal = Journal.find_by_id(options[:renew_id].to_i)

        if self.account_balances.size > 0
          entry = renew_journal.entries.create!(printed_at: to_close_at+1, :currency_id => renew_journal.currency_id)
          result   = 0
          gains    = Account.find_in_chart(:financial_year_profit)
          losses   = Account.find_in_chart(:financial_year_loss)
          charges  = Account.find_in_chart(:charge)
          products = Account.find_in_chart(:product)

          for balance in self.account_balances.joins(:account).order("number")
            if balance.account.number.to_s.match(/^(#{charges.number}|#{products.number})/)
              result += balance.balance
            elsif balance.balance != 0
              # TODO: Use currencies properly in account_balances !
              entry.items.create!(:account_id => balance.account_id, :name => balance.account.name, :real_debit => balance.balance_debit, :real_credit => balance.balance_credit)
            end
          end

          if result > 0
            entry.items.create!(:account_id => losses.id, :name => losses.name, :real_debit => result, :real_credit => 0.0)
          elsif result < 0
            entry.items.create!(:account_id => gains.id, :name => gains.name, :real_debit => 0.0, :real_credit => result.abs)
          end

        end
      end
    end
    return true
  end

  # this method returns the previous financial_year by default.
  def previous(n=1)
    return self.class.where(stopped_at: self.started_at-n).first
  end

  # this method returns the next financial_year by default.
  def next(n=1)
    return self.class.where(started_at: self.stopped_at+n).first
  end

  # Find or create the next financial year based on the date of the current
  def find_or_create_next
    year = self.next
    unless year
      months = 12
      if self.class.count != 1
        months = 0
        x = self.started_at
        while x <= self.stopped_at.beginning_of_month
          months += 1
          x = x + 1.month
        end
      end
      year = self.class.create(started_at: (self.stopped_at + 1.day), :stopped_at => (self.stopped_at + months.months), currency: self.currency)
    end
    return year
  end


  # Computes the value of list of accounts in a String
  # 123 will take.all accounts 123*
  # ^456 will remove.all accounts 456*
  # 789X will compute the balance although result is negative
  def balance(accounts, credit = false)
    normals, excepts, negatives, forceds = ["(XD)"], [], [], []
    for prefix in accounts.strip.split(/\s*[\,\s]+\s*/)
      code = prefix.gsub(/(^(\-|\^)|[CDX]+$)/, '')
      excepts   << code if prefix.match(/^\^\d+$/)
      negatives << code if prefix.match(/^\-\d+/)
      forceds   << code if prefix.match(/^\-?\d+[CDX]$/)
      normals   << code if prefix.match(/^\-?\d+[CDX]?$/)
    end

    balance = FinancialYear.balance_expr(credit)
    if forceds.size > 0 or negatives.size > 0
      forceds_and_negatives = forceds & negatives
      balance  = "CASE"
      balance << " WHEN "+forceds_and_negatives.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -#{FinancialYear.balance_expr(!credit, :forced => true)}" if forceds_and_negatives.size > 0
      balance << " WHEN "+forceds.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN #{FinancialYear.balance_expr(credit, :forced => true)}" if forceds.size > 0
      balance << " WHEN "+negatives.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -#{FinancialYear.balance_expr(!credit)}" if negatives.size > 0
      balance << " ELSE #{FinancialYear.balance_expr(credit)} END"
    end

    query  = "SELECT sum(#{balance}) AS balance FROM #{AccountBalance.table_name} AS ab JOIN #{Account.table_name} AS a ON (a.id=ab.account_id) WHERE ab.financial_year_id=#{self.id}"
    query << " AND ("+normals.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+")"
    query << " AND NOT ("+excepts.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+")" if excepts.size > 0
    balance = ActiveRecord::Base.connection.select_value(query)
    return (balance.blank? ? nil : balance.to_d)
  end

  # Computes and formats debit balance for an account regexp
  # Use I18n to produce string
  def debit_balance(accounts)
    if value = self.balance(accounts, false)
      return value.l(currency: self.currency)
    end
    return nil
  end

  # Computes and formats credit balance for an account regexp
  # Use I18n to produce string
  def credit_balance(accounts)
    if value = self.balance(accounts, true)
      return value.l(currency: self.currency)
    end
    return nil
  end


  def self.balance_expr(credit = false, options = {})
    columns = [:debit, :credit]
    columns.reverse! if credit
    prefix = (options[:record] ? options.delete(:record).to_s + "." : "") + "local_"
    if options[:forced]
      return "(#{prefix}#{columns[0]} - #{prefix}#{columns[1]})"
    else
      return "(CASE WHEN #{prefix}#{columns[0]} > #{prefix}#{columns[1]} THEN #{prefix}#{columns[0]} - #{prefix}#{columns[1]} ELSE 0 END)"
    end
  end



  # Re-create.all account_balances record for the financial year
  def compute_balances!
    results = ActiveRecord::Base.connection.select_all("SELECT account_id, sum(debit) AS debit, sum(credit) AS credit, count(id) AS count FROM #{JournalEntryItem.table_name} WHERE state != 'draft' AND printed_at BETWEEN #{self.class.connection.quote(self.started_at)} AND #{self.class.connection.quote(self.stopped_at)} GROUP BY account_id")
    self.account_balances.clear
    for result in results
      self.account_balances.create!(:account_id => result["account_id"].to_i, :local_count => result["count"].to_i, :local_credit => result["credit"].to_f, :local_debit => result["debit"].to_f)
    end
    return self
  end

  # Generate last journal entry with financial assets depreciations (option.ally)
  def generate_last_journal_entry(options = {})
    unless self.last_journal_entry
      self.create_last_journal_entry!(printed_at: self.stopped_at, :journal_id => options[:journal_id])
    end

    # Empty journal entry
    self.last_journal_entry.items.clear

    if options[:financial_assets_depreciations]
      for depreciation in self.financial_asset_depreciations.include(:financial_asset)
        name = tc(:bookkeep, resource: FinancialAsset.model_name.human, number: depreciation.financial_asset.number, name: depreciation.financial_asset.name, position: depreciation.position, total: depreciation.financial_asset.depreciations.count)
        # Charges
        self.last_journal_entry.add_debit(name, depreciation.financial_asset.charges_account, depreciation.amount)
        # Allocation
        self.last_journal_entry.add_credit(name, depreciation.financial_asset.allocation_account, depreciation.amount)
        depreciation.update_attributes(:journal_entry_id => self.last_journal_entry.id)
      end
    end
    return self
  end

end
