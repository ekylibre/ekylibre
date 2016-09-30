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
# == Table: journals
#
#  closed_on        :date             not null
#  code             :string           not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  custom_fields    :jsonb
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  nature           :string           not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  used_for_affairs :boolean          default(FALSE), not null
#  used_for_gaps    :boolean          default(FALSE), not null
#

class Journal < Ekylibre::Record::Base
  include Customizable
  attr_readonly :currency
  refers_to :currency
  has_many :cashes, dependent: :restrict_with_exception
  has_many :entry_items, class_name: 'JournalEntryItem', inverse_of: :journal, dependent: :destroy
  has_many :entries, class_name: 'JournalEntry', inverse_of: :journal, dependent: :destroy
  enumerize :nature, in: [:sales, :purchases, :bank, :forward, :various, :cash, :stocks], default: :various, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :code, :name, presence: true, length: { maximum: 500 }
  validates :currency, :nature, presence: true
  validates :used_for_affairs, :used_for_gaps, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :code, length: { allow_nil: true, maximum: 4 }
  validates :nature, length: { allow_nil: true, maximum: 30 }
  validates :code, uniqueness: true
  validates :name, uniqueness: true
  validates :code, format: { with: /\A[\dA-Z]+\z/ }

  selects_among_all :used_for_affairs, :used_for_gaps, if: :various?

  scope :used_for, lambda { |nature|
    unless Journal.nature.values.include?(nature.to_s)
      raise ArgumentError, "Journal#used_for must be one of these: #{Journal.nature.values.join(', ')}"
    end
    where(nature: nature.to_s)
  }
  scope :opened_on, lambda { |at|
    where(arel_table[:closed_on].lteq(at))
  }
  scope :sales,     -> { where(nature: 'sales') }
  scope :purchases, -> { where(nature: 'purchases') }
  scope :banks,     -> { where(nature: 'bank') }
  scope :forwards,  -> { where(nature: 'forward') }
  scope :various,   -> { where(nature: 'various') }
  scope :cashes,    -> { where(nature: 'cashes') }
  scope :stocks,    -> { where(nature: 'stocks') }
  scope :banks_or_cashes, -> { where(nature: 'cashes').or.where(nature: 'bank') }

  before_validation(on: :create) do
    if year = FinancialYear.first_of_all
      self.closed_on ||= (year.started_on - 1).end_of_day
    end
    self.closed_on ||= Time.new(1899, 12, 31).end_of_month
  end

  # this method is .alled before creation or validation method.
  before_validation do
    self.name = nature.l if name.blank? && nature
    if eoc = Entity.of_company
      self.currency ||= eoc.currency
    end
    self.code = nature.l if code.blank?
    self.code = code.codeize[0..3]
  end

  validate do
    if self.closed_on && FinancialYear.find_by(started_on: self.closed_on + 1).blank?
      if self.closed_on != self.closed_on.end_of_month
        errors.add(:closed_on, :end_of_month, closed_on: self.closed_on.l)
      end
    end
    unless code.blank?
      errors.add(:code, :taken) if others.find_by(code: code.to_s[0..3])
    end
  end

  protect(on: :destroy) do
    entries.any? || entry_items.any? || cashes.any?
  end

  class << self
    # Returns the default journal from preferences
    # Creates the journal if not exists
    def get(name)
      name = name.to_s
      pref_name = "#{name}_journal"
      raise ArgumentError, "Unvalid journal name: #{name.inspect}" unless self.class.preferences_reference.key? pref_name
      unless journal = preferred(pref_name)
        journal = journals.find_by_nature(name)
        journal = journals.create!(name: tc("default.journals.#{name}"), nature: name, currency: default_currency) unless journal
        prefer!(pref_name, journal)
      end
      journal
    end

    def used_for_affairs
      find_by(used_for_affairs: true)
    end

    # Load default journal if not exist
    def load_defaults
      nature.values.each do |nature|
        next if find_by(nature: nature)
        financial_year = FinancialYear.first_of_all
        closed_on = financial_year ? (financial_year.started_on - 1) : Date.new(1899, 12, 31).end_of_month
        create!(
          name: "enumerize.journal.nature.#{nature}".t,
          nature: nature,
          currency: Preference[:currency],
          closed_on: closed_on
        )
      end
    end
  end

  # Test if journal is closable
  def closable?(closed_on = nil)
    closed_on ||= Time.zone.today
    self.class.where(id: id).update_all(closed_on: Date.civil(1900, 12, 31)) if self.closed_on.nil?
    reload
    return false unless (closed_on << 1).end_of_month > self.closed_on
    true
  end

  def closures(noticed_on = nil)
    noticed_on ||= Time.zone.today
    array = []
    date = (self.closed_on + 1).end_of_month
    while date < noticed_on
      array << date
      date = (date + 1).end_of_month
    end
    array
  end

  # this method closes a journal.
  def close(closed_on)
    errors.add(:closed_on, :end_of_month) if self.closed_on != self.closed_on.end_of_month
    errors.add(:closed_on, :draft_entry_items, closed_on: closed_on.l) if entry_items.joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)").where(state: :draft).where(printed_on: (self.closed_on + 1)..closed_on).any?
    return false unless errors.empty?
    ActiveRecord::Base.transaction do
      entries.where(printed_on: (self.closed_on + 1)..closed_on).find_each(&:close)
      update_column(:closed_on, closed_on)
    end
    true
  end

  # Close a journal and force validation of draft entries to the given date
  def close!(closed_on)
    finished = false
    ActiveRecord::Base.transaction do
      entries.where(printed_on: (self.closed_on + 1)..closed_on, state: :draft).find_each(&:confirm)
      entries.where(printed_on: (self.closed_on + 1)..closed_on, state: :confirmed).find_each(&:close)
      update_column(:closed_on, closed_on)
      finished = true
    end
    finished
  end

  def reopenable?
    return false unless reopenings.any?
    true
  end

  def reopenings
    year = FinancialYear.current
    return [] if year.nil?
    array = []
    date = year.started_on - 1
    while date < self.closed_on
      array << date
      date = (date + 1).end_of_month
    end
    array
  end

  def reopen(closed_on)
    ActiveRecord::Base.transaction do
      for entry in entries.where(printed_on: (closed_on + 1)..self.closed_on)
        entry.reopen
      end
      update_column(:closed_on, closed_on)
    end
    true
  end

  # Takes the very last created entry in the journal to generate the entry number
  def next_number
    entry = entries.order(id: :desc).first
    number = entry ? entry.number : code.to_s.upcase + '000000'
    number.gsub!(/(9+)\z/, '0\1') if number =~ /[^\d]9+\z/
    number.succ!
    while entries.where(number: number).any?
      number.gsub!(/(9+)\z/, '0\1') if number =~ /[^\d]9+\z/
      number.succ!
    end
    number
  end

  # this method searches the last entries according to a number.
  def last_entries(period, count = 30)
    period.entries.order("LPAD(number, 20, '0') DESC").limit(count)
  end

  def entry_items_between(started_on, stopped_on)
    entry_items.joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)").where(printed_on: started_on..stopped_on).order('printed_on, journal_entries.id, journal_entry_items.id')
  end

  def entry_items_calculate(column, started_on, stopped_on, operation = :sum)
    column = (column == :balance ? "#{JournalEntryItem.table_name}.real_debit - #{JournalEntryItem.table_name}.real_credit" : "#{JournalEntryItem.table_name}.real_#{column}")
    entry_items.joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)").where(printed_on: started_on..stopped_on).calculate(operation, column)
  end

  # Computes the value of list of accounts in a String
  # Examples:
  #   132 !13245 !1325 D, - 52 56, 975 C
  #
  # '!' exclude computation
  # '+' does nothing. Permits to explicit direction
  # '-' negates values
  # Computation:
  #   B: Balance (= Debit - Credit). Default computation.
  #   C: Credit balance if positive
  #   D: Debit balance if positive
  def self.sum_entry_items(expression, options = {})
    conn = ActiveRecord::Base.connection
    journal_entry_items = 'jei'
    journal_entries = 'je'
    accounts = 'a'

    journal_entries_states = ''
    if options[:states]
      journal_entries_states = ' AND ' + JournalEntry.state_condition(options[:states], journal_entries)
    end

    from_where = " FROM #{JournalEntryItem.table_name} AS #{journal_entry_items} JOIN #{Account.table_name} AS #{accounts} ON (account_id=#{accounts}.id) JOIN #{JournalEntry.table_name} AS #{journal_entries} ON (entry_id=#{journal_entries}.id)"
    from_where << ' WHERE true'
    if options[:started_on] || options[:stopped_on]
      from_where << ' AND ' + JournalEntry.period_condition(:interval, options[:started_on], options[:stopped_on], journal_entries)
    end

    values = expression.split(/\,/).collect do |expr|
      words = expr.strip.split(/\s+/)
      direction = 1
      direction = -1 if words.first =~ /^(\+|\-)$/ && words.shift == '-'
      mode = words.last =~ /^[BCD]$/ ? words.delete_at(-1) : 'B'
      accounts_range = {}
      words.map do |word|
        position = (word =~ /\!/ ? :exclude : :include)
        strict = (word =~ /\@/)
        word.gsub!(/^[\!\@]+/, '')
        condition = "#{accounts}.number " + (strict ? "= '#{word}'" : "LIKE '#{word}%'")
        accounts_range[position] ||= []
        accounts_range[position] << condition
      end.join
      query = "SELECT SUM(#{journal_entry_items}.absolute_debit) AS debit, SUM(#{journal_entry_items}.absolute_credit) AS credit"
      query << from_where
      query << journal_entries_states
      query << " AND (#{accounts_range[:include].join(' OR ')})" if accounts_range[:include]
      query << " AND NOT (#{accounts_range[:exclude].join(' OR ')})" if accounts_range[:exclude]
      row = conn.select_rows(query).first
      debit =  row[0].blank? ? 0.0 : row[0].to_d
      credit = row[1].blank? ? 0.0 : row[1].to_d
      if mode == 'C'
        direction * (credit > debit ? credit - debit : 0)
      elsif mode == 'D'
        direction * (debit > credit ? debit - credit : 0)
      else
        direction * (debit - credit)
      end
    end
    values.sum
  end

  # Compute a trial balance with many options
  # * :started_on Use journal entries printed on after started_on
  # * :stopped_on Use journal entries printed on before stopped_on
  # * :draft      Use draft journal entry_items
  # * :confirmed  Use confirmed journal entry_items
  # * :closed     Use closed journal entry_items
  # * :accounts   Select ranges of accounts
  # * :centralize Select account's prefixe which permits to centralize
  def self.trial_balance(options = {})
    conn = ActiveRecord::Base.connection
    journal_entry_items = 'jei'
    journal_entries = 'je'
    accounts = 'a'

    journal_entries_states = ' AND (' + JournalEntry.state_condition(options[:states], journal_entries) + ')'

    account_range = ' AND (' + Account.range_condition(options[:accounts], accounts) + ')'

    centralize = options[:centralize].to_s.strip.split(/[^A-Z0-9]+/)
    centralized = '(' + centralize.collect { |c| "#{accounts}.number LIKE #{conn.quote(c + '%')}" }.join(' OR ') + ')'

    from_where  = " FROM #{JournalEntryItem.table_name} AS #{journal_entry_items} JOIN #{Account.table_name} AS #{accounts} ON (account_id=#{accounts}.id) JOIN #{JournalEntry.table_name} AS #{journal_entries} ON (entry_id=#{journal_entries}.id)"
    from_where += ' WHERE (' + JournalEntry.period_condition(options[:period], options[:started_on], options[:stopped_on], journal_entries) + ')'

    # Total
    items = []
    query = "SELECT '', -1, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), '#{'Z' * 16}' AS skey"
    query << from_where
    query << journal_entries_states
    query << account_range
    items += conn.select_rows(query)

    # Sub-totals
    for name, value in options.select { |k, v| k.to_s.match(/^level_\d+$/) && v.to_i == 1 }
      level = name.split(/\_/)[-1].to_i
      query = "SELECT SUBSTR(#{accounts}.number, 1, #{level}) AS subtotal, -2, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), SUBSTR(#{accounts}.number, 1, #{level})||'#{'Z' * (16 - level)}' AS skey"
      query << from_where
      query << journal_entries_states
      query << account_range
      query << " AND LENGTH(#{accounts}.number) >= #{level}"
      query << ' GROUP BY subtotal'
      items += conn.select_rows(query)
    end

    # NOT centralized accounts (default)
    query = "SELECT #{accounts}.number, #{accounts}.id AS account_id, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), #{accounts}.number AS skey"
    query << from_where
    query << journal_entries_states
    query << account_range
    query << " AND NOT #{centralized}" unless centralize.empty?
    query << " GROUP BY #{accounts}.id, #{accounts}.number"
    query << " ORDER BY #{accounts}.number"
    items += conn.select_rows(query)

    # Centralized accounts
    for prefix in centralize
      query = "SELECT SUBSTR(#{accounts}.number, 1, #{prefix.size}) AS centralize, -3, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), #{conn.quote(prefix)} AS skey"
      query << from_where
      query << journal_entries_states
      query << account_range
      query << " AND #{accounts}.number LIKE #{conn.quote(prefix + '%')}"
      query << ' GROUP BY centralize'
      items += conn.select_rows(query)
    end

    items.sort { |a, b| a[5] <=> b[5] }
  end
end
