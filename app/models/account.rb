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
# == Table: accounts
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  debtor       :boolean          default(FALSE), not null
#  description  :text
#  id           :integer          not null, primary key
#  label        :string           not null
#  last_letter  :string
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  number       :string           not null
#  reconcilable :boolean          default(FALSE), not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#  usages       :text
#

class Account < Ekylibre::Record::Base
  @@references = []
  attr_readonly :number
  # has_many :account_balances
  # has_many :attorneys, class_name: "Entity", foreign_key: :attorney_account_id
  has_many :balances, class_name: 'AccountBalance'
  has_many :cashes
  has_many :clients,             class_name: 'Entity', foreign_key: :client_account_id
  has_many :collected_taxes,     class_name: 'Tax', foreign_key: :collect_account_id
  has_many :commissioned_incoming_payment_modes, class_name: 'IncomingPaymentMode', foreign_key: :commission_account_id
  has_many :depositables_incoming_payment_modes, class_name: 'IncomingPaymentMode', foreign_key: :depositables_account_id
  # Not used:
  # has_many :fixed_assets_categories, class_name: "ProductNatureCategory", foreign_key: :fixed_asset_account_id
  # has_many :fixed_assets_depreciations, class_name: "ProductNatureCategory", foreign_key: :fixed_asset_allocation_account_id
  # has_many :fixed_asset_depreciations_inputations_expenses_categories, class_name: "ProductNatureCategory", foreign_key: :fixed_asset_expenses_account_id
  has_many :journal_entry_items,  class_name: 'JournalEntryItem'
  has_many :paid_taxes,           class_name: 'Tax', foreign_key: :deduction_account_id
  has_many :charges_categories,   class_name: 'ProductNatureCategory', foreign_key: :charge_account_id
  has_many :purchase_items,       class_name: 'PurchaseItem'
  has_many :sale_items,           class_name: 'SaleItem'
  has_many :products_categories,  class_name: 'ProductNatureCategory', foreign_key: :product_account_id
  has_many :stocks_categories,    class_name: 'ProductNatureCategory', foreign_key: :stock_account_id
  has_many :suppliers,            class_name: 'Entity', foreign_key: :supplier_account_id
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :debtor, :reconcilable, in: [true, false]
  validates_presence_of :label, :name, :number
  # ]VALIDATORS]
  validates_length_of :last_letter, allow_nil: true, maximum: 10
  validates_length_of :number, allow_nil: true, maximum: 20
  validates_length_of :name, allow_nil: true, maximum: 200
  validates_format_of :number, with: /\A\d(\d(\d[0-9A-Z]*)?)?\z/
  validates_uniqueness_of :number

  # default_scope order(:number, :name)
  scope :majors, -> { where("number LIKE '_'").order(:number, :name) }
  scope :of_usage, lambda { |usage|
    unless Nomen::Accounts[usage]
      fail ArgumentError, "Unknown usage #{usage.inspect}"
    end
    where('usages ~ E?', "\\\\m#{usage}\\\\M")
  }
  # return Account which contains usages mentionned (OR)
  scope :of_usages, lambda { |*usages|
    where('usages ~ E?', usages.sort.map { |usage| "\\\\m#{usage.to_s.gsub(/\W/, '')}\\\\M" }.join('.*|'))
  }

  scope :used_between, lambda { |started_at, stopped_at|
    # where("id IN (SELECT account_id FROM #{JournalEntryItem.table_name} WHERE printed_on BETWEEN ? AND ? )", started_at, stopped_at)
    where(id: JournalEntryItem.between(started_at, stopped_at).select(:account_id))
  }

  # scope :used_in_journal_entry_items, lambda { |started_at, stopped_at|
  #  joins("JOIN #{JournalEntryItem.table_name} AS journal_entry_items ON (journal_entry_items.account_id=id)").joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)").where(printed_on: started_at..stopped_at).order("printed_on, journal_entries.id, journal_entry_items.id")
  # }

  # scope :deposit_pending_payments, lambda { where('number LIKE ?', self.chart_number(:deposit_pending_payments)+"%").order(:number, :name) }
  # scope :attorney_thirds,          lambda { where('number LIKE ?', self.chart_number(:attorney_thirds)+"%").order(:number, :name) }
  scope :clients,   -> { of_usage(:clients) }
  scope :suppliers, -> { of_usage(:suppliers) }
  scope :attorneys, -> { of_usage(:attorneys) }
  scope :banks, -> { of_usage(:banks) }
  scope :cashes, -> { of_usage(:cashes) }
  scope :banks_or_cashes, -> { of_usages(:cashes, :banks) }
  scope :banks_or_cashes_or_associates, -> { of_usages(:cashes, :banks, :principal_associated_accounts, :associated_accounts, :usual_associated_accounts) }
  scope :thirds, -> { of_usages(:suppliers, :clients, :social_agricultural_mutuality, :usual_associated_accounts, :attorneys, :compensation_operations) }

  # scope :assets_depreciations, -> { where('number LIKE ?', '28%').order(:number, :name) }
  scope :assets_depreciations, lambda {
    of_usages(:incorporeal_asset_depreciations, :other_incorporeal_asset_depreciations, :corporeal_asset_depreciations,
              :land_parcel_asset_depreciations, :land_parcel_construction_asset_depreciations, :own_building_asset_depreciations,
              :other_building_asset_depreciations, :equipment_asset_depreciations, :other_corporeal_asset_depreciations,
              :general_installation_asset_depreciations, :transport_vehicle_asset_depreciations,
              :office_equipment_asset_depreciations, :office_furniture_asset_depreciations,
              :sustainable_packaging_asset_depreciations, :other_asset_depreciations,
              :biocorporeal_asset_depreciations, :adult_animal_asset_depreciations, :young_animal_asset_depreciations, :sustainables_plants_asset_depreciations)
  }

  # scope :asset_depreciations_inputations_expenses, -> { where('number LIKE ?', '68%').order(:number, :name) }
  scope :asset_depreciations_inputations_expenses, -> { of_usages(:incorporeals_depreciations_inputations_expenses, :land_parcel_construction_depreciations_inputations_expenses, :building_depreciations_inputations_expenses, :animals_depreciations_inputations_expenses, :equipments_depreciations_inputations_expenses, :others_corporeals_depreciations_inputations_expenses) }

  # scope :supplier_thirds,          lambda { where('number LIKE ?', self.chart_number(:supplier_thirds)+"%").order(:number, :name) }
  # scope :product_natures,          lambda { where('number LIKE ?', self.chart_number(:product_natures)+"%").order(:number, :name) }
  # scope :charges,                  lambda { where('number LIKE ?', self.chart_number(:charges)+"%").order(:number, :name) }
  # scope :banks,                    lambda { where('number LIKE ?', self.chart_number(:banks)+"%").order(:number, :name) }
  # scope :cashes,                   lambda { where('number LIKE ?', self.chart_number(:cashes)+"%").order(:number, :name) }
  # scope :collected_taxes,          lambda { where('number LIKE ?', self.chart_number(:taxes_collected)+"%").order(:number, :name) }
  # scope :paid_taxes,               lambda { where('number LIKE ?', self.chart_number(:taxes_paid)+"%").order(:number, :name) }

  # This method:allows to create the parent accounts if it is necessary.
  before_validation do
    self.reconcilable = self.reconcilableable? if reconcilable.nil?
    self.label = tc(:label, number: number.to_s, name: name.to_s)
  end

  protect(on: :destroy) do
    for r in self.class.reflect_on_all_associations(:has_many)
      return true if send(r.name).any?
    end
    return false
  end

  class << self
    # Create an account with its number (and name)
    # Account#get(number[, name][, options])
    def get(*args)
      ActiveSupport::Deprecation.warn('Account::get is deprecated. Please use Account::find_or_create_in_chart instead.')
      options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
      number = args.shift.to_s.strip
      options[:name] ||= args.shift
      numbers = Nomen::Accounts.items.values.collect { |i| i.send(chart) } # map(&chart.to_sym)
      while number =~ /0$/
        break if numbers.include?(number)
        number.gsub!(/0$/, '')
      end unless numbers.include?(number)
      item = Nomen::Accounts.items.values.detect { |i| i.send(chart) == number }
      if account = find_by_number(number)
        if item && !account.usages_array.include?(item)
          account.usages ||= ''
          account.usages << ' ' + item.name.to_s
          account.save!
        end
      else
        if item
          options[:name] ||= item.human_name
          options[:usages] ||= ''
          options[:usages] << ' ' + item.name.to_s
        end
        options[:name] ||= number.to_s
        account = create!(options.merge(number: number))
      end
      account
    end

    # Find account with its usage among all existing account records
    def find_in_chart(usage)
      unless account = of_usage(usage).first
        if item = Nomen::Accounts[usage]
          account = find_by(number: item.send(chart))
        end
      end
      account
    end

    # Find all account matching with the regexp in a String
    # 123 will take all accounts 123*
    # ^456 will remove all accounts 456*
    def regexp_condition(expr, options = {})
      table = options[:table] || table_name
      normals = ['(XD)']
      excepts = []
      for prefix in expr.strip.split(/[\,\s]+/)
        code = prefix.gsub(/(^(\-|\^)|[CDX]+$)/, '')
        excepts << code if prefix.match(/^\^\d+$/)
        normals << code if prefix.match(/^\-?\d+[CDX]?$/)
      end
      conditions = ''
      if normals.any?
        conditions << '(' + normals.sort.collect do|c|
          "#{table}.number LIKE '#{c}%'"
        end.join(' OR ') + ')'
      end
      if excepts.any?
        conditions << ' AND NOT (' + excepts.sort.collect do|c|
          "#{table}.number LIKE '#{c}%'"
        end.join(' OR ') + ')'
      end
      conditions
    end
    alias_method :find_with_regexp, :regexp_condition

    # Find all account matching with the regexp in a String
    # 123 will take all accounts 123*
    # ^456 will remove all accounts 456*
    def find_with_regexp(expr)
      where(regexp_condition(expr))
    end

    # Find or create an account with its name in chart if not exist in DB
    def find_or_create_in_chart(usage)
      if account = find_in_chart(usage)
        return account
      elsif item = Nomen::Accounts[usage]
        account = create!(name: item.human_name, number: item.send(chart), debtor: !!item.debtor, usages: item.name)
        return account
      else
        fail ArgumentError, "The usage #{usage.inspect} is unknown"
      end
    end

    # Returns the name of the used chart of accounts
    # It takes the information in preferences
    def chart
      Preference[:chart_of_accounts]
    end
    alias_method :chart_of_accounts, :chart

    # Returns the name of the used chart of accounts
    # It takes the information in preferences
    def chart=(name)
      unless item = Nomen::ChartsOfAccounts[name]
        fail ArgumentError, "The chart of accounts #{name.inspect} is unknown."
      end
      Preference.get(:chart_of_accounts).set!(item.name)
    end
    alias_method :chart_of_accounts=, :chart=

    # Returns the human name of the chart of accounts
    def chart_name(name = nil)
      Nomen::ChartsOfAccounts[name || chart].human_name
    end

    # Find.all available accounting systems in.all languages
    def charts
      Nomen::ChartsOfAccounts.all
    end

    # Load a chart of account
    def load_defaults # (name, options = {})
      transaction do
        # Destroy unused existing accounts
        find_each do |account|
          account.destroy if account.destroyable?
        end
        for item in Nomen::Accounts.all
          find_or_create_in_chart(item)
        end
      end
      true
    end

    # Clean ranges of accounts
    # Example : 1-3 41 43
    def clean_range_condition(range, _table_name = nil)
      expression = ''
      unless range.blank?
        valid_expr = /^\d(\d(\d[0-9A-Z]*)?)?$/
        for expr in range.split(/[^0-9A-Z\-\*]+/)
          if expr.match(/\-/)
            start, finish = expr.split(/\-+/)[0..1]
            next unless start < finish && start.match(valid_expr) && finish.match(valid_expr)
            expression << " #{start}-#{finish}"
          elsif expr.match(valid_expr)
            expression << " #{expr}"
          end
        end
      end
      expression.strip
    end

    # Build an SQL condition to restrein accounts to some ranges
    # Example : 1-3 41 43
    def range_condition(range, table_name = nil)
      conditions = []
      if range.blank?
        return connection.quoted_true
      else
        range = clean_range_condition(range)
        table = table_name || Account.table_name
        for expr in range.split(/\s+/)
          if expr.match(/\-/)
            start, finish = expr.split(/\-+/)[0..1]
            max = [start.length, finish.length].max
            conditions << "#{connection.substr(table + '.number', 1, max)} BETWEEN #{connection.quote(start.ljust(max, '0'))} AND #{connection.quote(finish.ljust(max, 'Z'))}"
          else
            conditions << "#{table}.number LIKE #{connection.quote(expr + '%%')}"
          end
        end
      end
      '(' + conditions.join(' OR ') + ')'
    end

    # Returns list of reconcilable prefixes defined in preferences
    def reconcilable_prefixes
      [:client, :supplier, :attorney].collect do |mode|
        Nomen::Accounts[mode].send(chart).to_s
      end
    end

    # Returns a RegExp based on reconcilable_prefixes
    def reconcilable_regexp
      Regexp.new("^(#{reconcilable_prefixes.join('|')})")
    end
  end

  # Returns list of usages as an array of usage items from the nomenclature
  def usages_array
    usages.to_s.strip.split(/[\,\s]/).collect do |i|
      Nomen::Accounts[i]
    end.compact
  end

  # # Return the number corresponding to the name
  # def self.chart_number(name)
  #   return ""
  # end

  # def self.get(number, name=nil)
  #   number = number.to_s
  #   account = self.find_by_number(number)
  #   return account || self.create!(:number => number, :name => name || number.to_s)
  # end

  # def self.human_chart_name(chart)
  #   return ::I18n.translate("accounting_systems.#{chart}.name")
  # end

  # # Find.all available accounting systems in.all languages
  # def self.charts
  #   ac = ::I18n.translate("accounting_systems")
  #   return (ac.is_a?(Hash) ? ac.keys : [])
  # end

  # # Replace current chart of account with a new
  # def self.load_chart(name, options = {})
  #   chart = ::I18n.translate("accounting_systems.#{name}")
  #   if chart.is_a? Hash

  #     self.transaction do
  #       # Destroy unused existing accounts
  #       self.destroy_all

  #       regexp = self.reconcilable_regexp

  #       # Existing accounts
  #       self.find_each do |account|
  #         account.update_column(:reconcilable, true) if account.number.match(regexp)
  #       end if options[:reconcilable]

  #       # Create new accounts
  #       for num, name in chart.all.sort{|a,b| a[0].to_s <=>  b[0].to_s}.select{|k, v| k.to_s.match(/^n\_/)}
  #         number = num.to_s[2..-1]
  #         if account = self.find_by_number(number)
  #           account.update_attributes!(:name => name, :reconcilable => (options[:reconcilable] and number.match(regexp)))
  #         else
  #           raise number.inspect unless self.create(:number => number, :name => name, :reconcilable => (number.match(regexp) ? true : false))
  #         end
  #       end
  #     end
  #     return true
  #   end
  #   return false
  # end

  # Check if the account is a third account and therefore returns if it should be reconcilable
  def reconcilableable?
    (number.to_s.match(self.class.reconcilable_regexp) ? true : false)
  end

  def reconcilable_entry_items(period, started_at, stopped_at)
    # self.journal_entry_items.joins("JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id)").where(JournalEntry.period_condition(period, started_at, stopped_at, 'je')).reorder("letter DESC, je.number DESC, #{JournalEntryItem.table_name}.position")
    journal_entry_items.joins("JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id)").where(JournalEntry.period_condition(period, started_at, stopped_at, 'je')).reorder('letter DESC, je.printed_on')
  end

  def new_letter
    letter = last_letter
    letter = letter.blank? ? 'AAA' : letter.succ
    update_column(:last_letter, letter)
    # item = self.journal_entry_items.where("LENGTH(TRIM(letter)) > 0").order("letter DESC").first
    # return (item ? item.letter.succ : "AAA")
    letter
  end

  # Finds entry items to mark, checks their "markability" and
  # if.all valids mark.all with a new letter or the first defined before
  def mark_entries(*journal_entries)
    ids = journal_entries.flatten.compact.collect(&:id)
    mark(journal_entry_items.where(entry_id: ids).map(&:id))
  end

  # Mark entry items with the given +letter+. If no +letter+ given, it uses a new letter.
  # Don't mark unless.all the marked items will be balanced together
  def mark(item_ids, letter = nil)
    conditions = ['id IN (?) AND (letter IS NULL OR LENGTH(TRIM(letter)) <= 0)', item_ids]
    items = journal_entry_items.where(conditions)
    return nil unless item_ids.size > 1 && items.count == item_ids.size && items.collect { |l| l.debit - l.credit }.sum.to_f.zero?
    letter ||= new_letter
    journal_entry_items.where(conditions).update_all(letter: letter)
    letter
  end

  # Unmark.all the entry items concerned by the +letter+
  def unmark(letter)
    journal_entry_items.where(letter: letter).update_all(letter: nil)
  end

  # Check if the balance of the entry items of the given +letter+ is zero.
  def balanced_letter?(letter)
    items = journal_entry_items.where('letter = ?', letter.to_s)
    return true if items.count.zero?
    items.sum('debit-credit').to_f.zero?
  end

  # Compute debit, credit, balance, balance_debit and balance_credit of the account
  # with.all the entry items
  def totals
    hash = {}
    hash[:debit]  = journal_entry_items.sum(:debit)
    hash[:credit] = journal_entry_items.sum(:credit)
    hash[:balance_debit] = 0.0
    hash[:balance_credit] = 0.0
    hash[:balance] = (hash[:debit] - hash[:credit]).abs
    hash["balance_#{hash[:debit] > hash[:credit] ? 'debit' : 'credit'}".to_sym] = hash[:balance]
    hash
  end

  # def journal_entry_items_between(started_at, stopped_at)
  #   self.journal_entry_items.joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)").where(printed_on: started_at..stopped_at).order("printed_on, journal_entries.id, #{JournalEntryItem.table_name}.id")
  # end

  def journal_entry_items_calculate(column, started_at, stopped_at, operation = :sum)
    column = (column == :balance ? "#{JournalEntryItem.table_name}.real_debit - #{JournalEntryItem.table_name}.real_credit" : "#{JournalEntryItem.table_name}.real_#{column}")
    journal_entry_items.where(printed_on: started_at..stopped_at).calculate(operation, column)
  end

  # This method loads the balance for a given period.
  def self.balance(from, to, list_accounts = [])
    balance = []
    conditions = '1=1'
    unless list_accounts.empty?
      conditions += ' AND ' + list_accounts.collect do |account|
        "number LIKE '" + account.to_s + "%'"
      end.join(' OR ')
    end
    accounts = Account.where(conditions).order('number ASC')
    # solde = 0

    res_debit = 0
    res_credit = 0
    res_balance = 0

    for account in accounts
      debit  = account.journal_entry_items.sum(:debit,  conditions: { 'r.created_at' => from..to }, joins: "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryItem.table_name}.entry_id").to_f
      credit = account.journal_entry_items.sum(:credit, conditions: { 'r.created_at' => from..to }, joins: "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryItem.table_name}.entry_id").to_f

      compute = HashWithIndifferentAccess.new
      compute[:id] = account.id.to_i
      compute[:number] = account.number.to_i
      compute[:name] = account.name.to_s
      compute[:debit] = debit
      compute[:credit] = credit
      compute[:balance] = debit - credit

      if debit.zero? || credit.zero?
        compute[:debit] = debit
        compute[:credit] = credit
      end

      # if not debit.zero? and not credit.zero?
      #         if compute[:balance] > 0
      #           compute[:debit] = compute[:balance]
      #           compute[:credit] = 0
      #         else
      #           compute[:debit] = 0
      #           compute[:credit] = compute[:balance].abs
      #         end
      #       end

      # if account.number.match /^12/
      # raise StandardError.new compute[:balance].to_s
      # end

      if account.number.match /^(6|7)/
        res_debit += compute[:debit]
        res_credit += compute[:credit]
        res_balance += compute[:balance]
      end

      # solde += compute[:balance] if account.number.match /^(6|7)/
      #      raise StandardError.new solde.to_s if account.number.match /^(6|7)/
      balance << compute
    end
    # raise StandardError.new res_balance.to_s
    balance.each do |account|
      if res_balance > 0
        if account[:number].to_s.match /^12/
          account[:debit] += res_debit
          account[:credit] += res_credit
          account[:balance] += res_balance # solde
        end
      elsif res_balance < 0
        if account[:number].to_s.match /^129/
          account[:debit] += res_debit
          account[:credit] += res_credit
          account[:balance] += res_balance # solde
        end
      end
    end
    # raise StandardError.new(balance.inspect)
    balance.compact
  end

  # this method loads the general ledger for.all the accounts.
  def self.ledger(from, to)
    ledger = []
    accounts = Account.order('number ASC')
    accounts.each do |account|
      compute = [] # HashWithIndifferentAccess.new

      journal_entry_items = account.journal_entry_items.where('r.created_at' => from..to).joins("INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryItem.table_name}.entry_id").order('r.number ASC')

      if journal_entry_items.size > 0
        entries = []
        compute << account.number.to_i
        compute << account.name.to_s
        journal_entry_items.each do |e|
          entry = HashWithIndifferentAccess.new
          entry[:date] = e.entry.created_at
          entry[:name] = e.name.to_s
          entry[:number_entry] = e.entry.number
          entry[:journal] = e.entry.journal.name.to_s
          entry[:credit] = e.credit
          entry[:debit] = e.debit
          entries << entry
          # compute[:journal_entry_items] << entry
        end
        compute << entries
        ledger << compute
      end
    end

    ledger.compact
  end
end
