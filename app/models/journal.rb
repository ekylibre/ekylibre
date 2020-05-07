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
# == Table: journals
#
#  accountant_id                      :integer
#  closed_on                          :date             not null
#  code                               :string           not null
#  created_at                         :datetime         not null
#  creator_id                         :integer
#  currency                           :string           not null
#  custom_fields                      :jsonb
#  id                                 :integer          not null, primary key
#  lock_version                       :integer          default(0), not null
#  name                               :string           not null
#  nature                             :string           not null
#  provider                           :jsonb
#  updated_at                         :datetime         not null
#  updater_id                         :integer
#  used_for_affairs                   :boolean          default(FALSE), not null
#  used_for_gaps                      :boolean          default(FALSE), not null
#  used_for_permanent_stock_inventory :boolean          default(FALSE), not null
#  used_for_tax_declarations          :boolean          default(FALSE), not null
#  used_for_unbilled_payables         :boolean          default(FALSE), not null
#

class Journal < Ekylibre::Record::Base
  include Customizable
  include Providable
  attr_readonly :currency
  refers_to :currency
  belongs_to :accountant, class_name: 'Entity'
  has_many :cashes, dependent: :restrict_with_exception
  has_many :entry_items, class_name: 'JournalEntryItem', inverse_of: :journal, dependent: :destroy
  has_many :entries, class_name: 'JournalEntry', inverse_of: :journal, dependent: :destroy
  has_many :incoming_payment_modes, foreign_key: :depositables_journal_id, dependent: :restrict_with_exception
  has_many :purchase_natures, dependent: :restrict_with_exception
  has_many :sale_natures, dependent: :restrict_with_exception
  has_many :inventories, inverse_of: :journal
  enumerize :nature, in: %i[sales purchases fixed_assets bank forward various cash stocks closure result], default: :various, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :code, :name, presence: true, length: { maximum: 500 }
  validates :currency, :nature, presence: true
  validates :used_for_affairs, :used_for_gaps, :used_for_permanent_stock_inventory, :used_for_tax_declarations, :used_for_unbilled_payables, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :nature, length: { allow_nil: true, maximum: 30 }
  validates :code, uniqueness: true, format: { with: /\A[A-Z0-9]+\z/ }, length: { maximum: 4 }
  validates :name, uniqueness: true
  validates :accountant, absence: true, unless: :various_without_cash?

  selects_among_all :used_for_affairs, :used_for_gaps, :used_for_unbilled_payables, if: :various?, scope: :currency
  selects_among_all :used_for_permanent_stock_inventory, if: :stocks?, scope: :currency

  scope :used_for, lambda { |nature|
    unless Journal.nature.values.include?(nature.to_s)
      raise ArgumentError, "Journal#used_for must be one of these: #{Journal.nature.values.join(', ')}"
    end
    where(nature: nature.to_s)
  }
  scope :opened_on, lambda { |at|
    where(arel_table[:closed_on].lteq(at))
  }
  scope :sales,           -> { where(nature: 'sales') }
  scope :purchases,       -> { where(nature: 'purchases') }
  scope :banks,           -> { where(nature: 'bank') }
  scope :closures,        -> { where(nature: 'closure') }
  scope :forwards,        -> { where(nature: 'forward') }
  scope :various,         -> { where(nature: 'various') }
  scope :cashes,          -> { where(nature: 'cash') }
  scope :results,         -> { where(nature: 'result') }
  scope :stocks,          -> { where(nature: 'stocks') }
  scope :fixed_assets,    -> { where(nature: 'fixed_asset') }
  scope :banks_or_cashes, -> { where(nature: %w[cashes bank]) }

  before_validation(on: :create) do
    self.closed_on ||= FinancialYear.last_closure
    if (year = FinancialYear.first_of_all)
      self.closed_on ||= (year.started_on - 1).end_of_day
    end
    self.closed_on ||= Time.new(1899, 12, 31).end_of_month
  end

  # this method is .alled before creation or validation method.
  before_validation do
    if eoc = Entity.of_company
      self.currency ||= eoc.currency
    end
    if code =~ /\A\?+\z/
      self.code = nature.l.codeize.gsub(/[^\d[A-Z]]+/, '')[0..[3, code.size - 1].min]
      code.succ! while Journal.where('code = ? AND id != ?', code, id || 0).any?
    elsif code.blank?
      self.code = nature.l
    end
    self.code = code.codeize.gsub(/[^\d[A-Z]]+/, '')[0..3]
  end

  validate do
    last_closure = FinancialYear.last_closure
    if last_closure.present?
      if self.closed_on < last_closure
        errors.add(:closed_on, :posterior, to: last_closure.l)
      end
    end
    if self.closed_on && FinancialYear.find_by(started_on: self.closed_on + 1).blank?
      if self.closed_on != self.closed_on.end_of_month
        errors.add(:closed_on, :end_of_month, closed_on: self.closed_on.l)
      end
    end
    if persisted? && accountant_id_changed?
      if accountant_has_financial_year_with_opened_exchange?(accountant)
        errors.add(:accountant, :entity_frozen)
      elsif accountant_has_financial_year_with_opened_exchange?(accountant_id_was)
        errors.add(:accountant, :previous_entity_frozen)
      end
    end
  end

  before_save if: :accountant_id_changed? do
    if accountant
      entries.where(state: :draft).find_each(&:confirm!)
      entries.where(state: :confirmed).find_each(&:close!)
    end
  end

  protect(on: :destroy) do
    entries.any? || entry_items.any? || cashes.any? || sale_natures.any? ||
      purchase_natures.any? || incoming_payment_modes.any?
  end


  # Prints human name of current state
  def nature_label
    self.class.nature_label(self.nature)
  end

  class << self
    def nature_label(nature)
      tc('natures.' + nature.to_s)
    end

    # Build an SQL condition based on options which should contains natures
    # @deprecated
    def nature_condition(natures = {}, table_name = nil)
      condition_builder.nature_condition(natures, table_name: table_name || self.table_name)
    end

    # Returns the default journal from preferences
    # Creates the journal if not exists
    def get(name)
      name = name.to_s
      pref_name = "#{name}_journal"
      raise ArgumentError, "Unvalid journal name: #{name.inspect}" unless self.class.preferences_reference.key? pref_name
      unless journal = preferred(pref_name)
        journal = journals.find_by(nature: name)
        journal ||= journals.create!(name: tc("default.journals.#{name}"), nature: name, currency: default_currency)
        prefer!(pref_name, journal)
      end
      journal
    end

    def used_for_affairs
      find_by(used_for_affairs: true)
    end

    def used_for_gaps!(attributes = {})
      attributes[:name] ||= :profits_and_losses.tl
      attributes[:code] ||= '??'
      attributes[:nature] ||= :various
      attributes[:used_for_gaps] = true
      journal = Journal.find_by(used_for_gaps: true)
      journal ||= Journal.find_by(attributes.slice(:name))
      journal || Journal.create!(attributes)
    end

    def used_for_tax_declarations!(attributes = {})
      attributes[:name] ||= :taxes.tl
      attributes[:code] ||= '??'
      attributes[:nature] ||= :various
      attributes[:used_for_tax_declarations] = true
      journal = Journal.find_by(used_for_tax_declarations: true)
      journal ||= Journal.find_by(attributes.slice(:name))
      journal || Journal.create!(attributes)
    end

    def used_for_permanent_stock_inventory!(attributes = {})
      attributes[:name] ||= :permanent_stock_inventory.tl
      attributes[:code] ||= '??'
      attributes[:nature] ||= :stocks
      attributes[:used_for_permanent_stock_inventory] = true
      journal = Journal.find_by(used_for_permanent_stock_inventory: true)
      journal ||= Journal.find_by(attributes.slice(:name))
      journal || Journal.create!(attributes)
    end

    def used_for_unbilled_payables!(attributes = {})
      attributes[:name] ||= :unbilled_payables.tl
      attributes[:code] ||= '??'
      attributes[:nature] ||= :various
      attributes[:used_for_unbilled_payables] = true
      journal = Journal.find_by(used_for_unbilled_payables: true)
      journal ||= Journal.find_by(attributes.slice(:name))
      journal || Journal.create!(attributes)
    end

    def create_one!(nature, currency, attributes = {})
      attributes[:name] = "enumerize.journal.nature.#{nature}".t + ' ' + currency
      if Journal.find_by(name: attributes[:name])
        attributes[:name] += ' 2'
        attributes[:name].succ! while Journal.find_by(name: attributes[:name])
      end
      attributes[:code] ||= '??'
      attributes[:nature] = nature
      attributes[:currency] = currency
      Journal.create!(attributes)
    end

    # Load default journal if not exist
    def load_defaults(**_options)
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

    private

      # @deprecated
      def condition_builder
        ActiveSupport::Deprecation.warn 'Journal condition methods are deprecated, use Accountancy::ConditionBuilder::* instead'
        Accountancy::ConditionBuilder::JournalConditionBuilder.new(connection: self.class.connection)
      end
  end

  def writable_on?(printed_on)
    printed_on > self.closed_on &&
      FinancialYearExchange.where('? BETWEEN started_on AND stopped_on', printed_on).empty?
  end

  # Test if journal is closable
  def closable?(new_closed_on = nil)
    new_closed_on ||= (Time.zone.today << 1).end_of_month
    return false if new_closed_on.end_of_month != new_closed_on
    return false if new_closed_on < self.closed_on
    true
  end

  def closures(noticed_on = nil)
    noticed_on ||= Time.zone.today
    array = []
    date = [(self.closed_on + 1), FinancialYear.last_closure].compact.max.end_of_month
    while date < noticed_on
      array << date
      date = (date + 1).end_of_month
    end
    array
  end

  # this method closes a journal.
  def close(new_closed_on)
    if new_closed_on != new_closed_on.end_of_month
      errors.add(:closed_on, :end_of_month, closed_on: new_closed_on.l)
    end
    if entry_items.joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)").where(state: :draft).where(printed_on: (self.closed_on + 1)..new_closed_on).any?
      errors.add(:closed_on, :draft_entry_items, closed_on: new_closed_on.l)
    end
    return false unless errors.empty?
    ActiveRecord::Base.transaction do
      entries.where(printed_on: (self.closed_on + 1)..new_closed_on).find_each(&:close)
      update_column(:closed_on, new_closed_on)
    end
    true
  end

  # Close a journal and force validation of draft entries to the given date
  def close!(closed_on)
    finished = false
    ActiveRecord::Base.transaction do
      JournalEntryItem.where(journal_id: id).where('printed_on <= ?', closed_on).where.not(state: :closed).update_all(state: :closed)
      JournalEntry.where(journal_id: id).where('printed_on <= ?', closed_on).where.not(state: :closed).update_all(state: :closed)
      update_column(:closed_on, closed_on)
      finished = true
    end
    finished
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

  def various_without_cash?
    various? && cashes.empty?
  end

  def booked_for_accountant?
    accountant
  end

  def accountant_has_financial_year_with_opened_exchange?(accountant_or_accountant_id)
    accountant = accountant_or_accountant_id.is_a?(Integer) ? Entity.find(accountant_or_accountant_id) : accountant_or_accountant_id
    accountant && accountant.financial_year_with_opened_exchange?
  end


  class << self
    # Computes the value of list of accounts in a String
    # Examples:
    #   132 !13245 !1325 D, - 52 56, 975 C
    #
    # '!' exclude computation
    # '+' does nothing. Permits to explicit direction
    # '-' negates values
    # Computation:
    #   B: Balance (= Debit - Credit). Default computation.
    #   C: -Balance if positive
    #   D: Balance if positive
    #   E: - Crédit balance
    #   F: Débit balance
    def sum_entry_items(expression, options = {})
      conn = ActiveRecord::Base.connection
      journal_entry_items = 'jei'
      journal_entries = 'je'
      journals = 'j'
      accounts = 'a'

      journal_entries_states = ''
      if options[:states]
        journal_entries_states = ' AND ' + JournalEntry.state_condition(options[:states], journal_entries)
      end

      from_where = " FROM #{JournalEntryItem.table_name} AS #{journal_entry_items} JOIN #{Account.table_name} AS #{accounts} ON (account_id=#{accounts}.id) JOIN #{JournalEntry.table_name} AS #{journal_entries} ON (entry_id=#{journal_entries}.id)"
      if options[:unwanted_journal_nature]
        from_where << " JOIN #{Journal.table_name} AS #{journals} ON (#{journal_entries}.journal_id=#{journals}.id)"
        from_where << " WHERE #{journals}.nature NOT IN (" + options[:unwanted_journal_nature].map { |c| "'#{c}'" }.join(', ') + ')'
      else
        from_where << ' WHERE true'
      end
      if options[:started_on] || options[:stopped_on]
        from_where << ' AND ' + JournalEntry.period_condition(:interval, options[:started_on], options[:stopped_on], journal_entries)
      end

      values = expression.split(/\,/).collect do |expr|
        words = expr.strip.split(/\s+/)
        direction = 1
        direction = -1 if words.first =~ /^(\+|\-)$/ && words.shift == '-'
        mode = words.last =~ /^[BCDEF]$/ ? words.delete_at(-1) : 'B'
        accounts_range = {}
        words.map do |word|
          position = (word =~ /\!/ ? :exclude : :include)
          strict = (word =~ /\@/)
          word.gsub!(/^[\!\@]+/, '')
          condition = "#{accounts}.number " + (strict ? "= '#{word}'" : "LIKE '#{word}%'")
          accounts_range[position] ||= []
          accounts_range[position] << condition
        end.join

        query = <<~SQL
          SELECT
            SUM(account_summary.sum_debit) as sum_debit,
            SUM(account_summary.sum_credit) AS sum_credit,
            SUM(CASE WHEN account_summary.account_balance > 0 THEN account_summary.account_balance ELSE 0 END) as debit_balance,
            SUM(CASE WHEN account_summary.account_balance < 0 THEN account_summary.account_balance ELSE 0 END) as credit_balance
          FROM (
            SELECT a.number,
              sum(COALESCE(jei.debit, 0)) as sum_debit,
              sum(COALESCE(jei.credit, 0)) as sum_credit,
              sum(COALESCE(jei.debit, 0)) - sum(COALESCE(jei.credit, 0)) as account_balance
        SQL

        query << from_where
        query << journal_entries_states
        query << " AND (#{accounts_range[:include].join(' OR ')})" if accounts_range[:include]
        query << " AND NOT (#{accounts_range[:exclude].join(' OR ')})" if accounts_range[:exclude]

        query << "GROUP BY a.id ORDER BY a.number) as account_summary"

        req = conn.select_rows(query)
        row = req.first
        debit =  row[0].blank? ? 0.0 : row[0].to_d
        credit = row[1].blank? ? 0.0 : row[1].to_d
        debit_balance = row[2].blank? ? 0.0 : row[2].to_d
        credit_balance = row[3].blank? ? 0.0 : row[3].to_d
        if mode == 'C'
          c = direction * (credit > debit ? credit - debit : 0)
        elsif mode == 'D'
          d = direction * (debit > credit ? debit - credit : 0)
        elsif mode == 'E'
          e = direction * (-credit_balance)
        elsif mode == 'F'
          f = direction * debit_balance
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
    #
    # @deprecated
    def trial_balance(options = {})
      trial_balance_calculator.trial_balance(options)
    end

    # @deprecated
    def trial_balance_calculator
      ActiveSupport::Deprecation.warn "trial_balance* methods are deprecated, use "
      Accountancy::TrialBalanceCalculator.build(connection: connection)
    end

    # @option states
    # @option natures
    # @option balance
    # @option accounts
    # @option centralize
    # @option period
    # @option started_on
    # @option stopped_on
    # @option previous_year
    #
    # @deprecated
    def trial_balance_dataset(**options)
      trial_balance_calculator.trial_balance_dataset(**options)
    end
  end
end
