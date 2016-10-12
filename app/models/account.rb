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
# == Table: accounts
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  custom_fields :jsonb
#  debtor        :boolean          default(FALSE), not null
#  description   :text
#  id            :integer          not null, primary key
#  label         :string           not null
#  last_letter   :string
#  lock_version  :integer          default(0), not null
#  name          :string           not null
#  number        :string           not null
#  reconcilable  :boolean          default(FALSE), not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#  usages        :text
#

class Account < Ekylibre::Record::Base
  include Customizable
  @@references = []
  attr_readonly :number
  # has_many :account_balances
  # has_many :attorneys, class_name: "Entity", foreign_key: :attorney_account_id
  has_many :balances, class_name: 'AccountBalance', dependent: :destroy
  has_many :cashes, dependent: :restrict_with_exception
  has_many :clients,             class_name: 'Entity', foreign_key: :client_account_id
  has_many :collected_taxes,     class_name: 'Tax', foreign_key: :collect_account_id
  has_many :commissioned_incoming_payment_modes, class_name: 'IncomingPaymentMode',
                                                 foreign_key: :commission_account_id
  has_many :depositables_incoming_payment_modes, class_name: 'IncomingPaymentMode',
                                                 foreign_key: :depositables_account_id
  has_many :journal_entry_items,  class_name: 'JournalEntryItem', dependent: :restrict_with_exception
  has_many :paid_taxes,           class_name: 'Tax', foreign_key: :deduction_account_id
  has_many :charges_categories,   class_name: 'ProductNatureCategory', foreign_key: :charge_account_id
  has_many :purchase_items,       class_name: 'PurchaseItem', dependent: :restrict_with_exception
  has_many :sale_items,           class_name: 'SaleItem'
  has_many :products_categories,  class_name: 'ProductNatureCategory', foreign_key: :product_account_id
  has_many :stocks_categories,    class_name: 'ProductNatureCategory', foreign_key: :stock_account_id
  has_many :suppliers,            class_name: 'Entity', foreign_key: :supplier_account_id
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :debtor, :reconcilable, inclusion: { in: [true, false] }
  validates :description, :usages, length: { maximum: 500_000 }, allow_blank: true
  validates :label, :name, :number, presence: true, length: { maximum: 500 }
  validates :last_letter, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :last_letter, length: { allow_nil: true, maximum: 10 }
  validates :number, length: { allow_nil: true, maximum: 20 }
  validates :name, length: { allow_nil: true, maximum: 200 }
  validates :number, format: { with: /\A\d(\d(\d[0-9A-Z]*)?)?\z/ }
  validates :number, uniqueness: true

  # default_scope order(:number, :name)
  scope :majors, -> { where("number LIKE '_'").order(:number, :name) }
  scope :of_usage, lambda { |usage|
    unless Nomen::Account.find(usage)
      raise ArgumentError, "Unknown usage #{usage.inspect}"
    end
    where('usages ~ E?', "\\\\m#{usage}\\\\M")
  }
  # return Account which contains usages mentionned (OR)
  scope :of_usages, lambda { |*usages|
    where('usages ~ E?', usages.sort.map { |usage| "\\\\m#{usage.to_s.gsub(/\W/, '')}\\\\M" }.join('.*|')).reorder(:number)
  }

  scope :used_between, lambda { |started_at, stopped_at|
    # where("id IN (SELECT account_id FROM #{JournalEntryItem.table_name} WHERE printed_on BETWEEN ? AND ? )", started_at, stopped_at)
    where(id: JournalEntryItem.between(started_at, stopped_at).select(:account_id))
  }

  scope :clients,   -> { of_usages(:clients, :social_agricultural_mutuality, :usual_associates_current_accounts) }
  scope :suppliers, -> { of_usages(:suppliers, :social_agricultural_mutuality, :usual_associates_current_accounts) }
  scope :employees, -> { of_usages(:staff_due_remunerations) }
  scope :attorneys, -> { of_usage(:attorneys) }
  scope :banks, -> { of_usage(:banks) }
  scope :cashes, -> { of_usage(:cashes) }
  scope :banks_or_cashes, -> { of_usages(:cashes, :banks) }
  scope :banks_or_cashes_or_associates, -> { of_usages(:cashes, :banks, :principal_associates_current_accounts, :associates_current_accounts, :usual_associates_current_accounts, :associates_frozen_accounts) } # , :owner_account doesn't exist
  scope :thirds, -> { of_usages(:suppliers, :clients, :social_agricultural_mutuality, :usual_associates_current_accounts, :attorneys, :compensation_operations) }

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

  scope :stocks_variations, -> {
    of_usages(:fertilizer_stocks_variation, :seed_stocks_variation, :plant_medicine_stocks_variation,
              :livestock_feed_stocks_variation, :animal_medicine_stocks_variation, :animal_reproduction_stocks_variation,
              :merchandising_stocks_variation, :adult_reproductor_animals_inventory_variations, :young_reproductor_animals_inventory_variations,
              :long_cycle_product_inventory_variations, :short_cycle_product_inventory_variations,
              :stocks_variation, :supply_stocks_variation, :other_supply_stocks_variation)
  }

  # This method:allows to create the parent accounts if it is necessary.
  before_validation do
    self.reconcilable = reconcilableable? if reconcilable.nil?
    self.label = tc(:label, number: number.to_s, name: name.to_s)
    self.usages = Account.find_parent_usage(number) if usages.blank? && number
  end

  protect(on: :destroy) do
    for r in self.class.reflect_on_all_associations(:has_many)
      return true if send(r.name).any?
    end
    return false
  end

  class << self
    # Create an account with its number (and name)
    def find_or_create_by_number(*args)
      options = args.extract_options!
      number = args.shift.to_s.strip
      options[:name] ||= args.shift
      numbers = Nomen::Account.items.values.collect { |i| i.send(accounting_system) }
      while number =~ /0$/
        break if numbers.include?(number)
        number.gsub!(/0$/, '')
      end unless numbers.include?(number)
      item = Nomen::Account.items.values.detect { |i| i.send(accounting_system) == number }
      account = find_by_number(number)
      if account
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
    def find_in_nomenclature(usage)
      account = of_usage(usage).first
      unless account
        item = Nomen::Account[usage]
        account = find_by(number: item.send(accounting_system)) if item
      end
      account
    end

    # Find usage in parent account by number
    def find_parent_usage(number)
      number = number.to_s

      parent_accounts = nil
      items = nil

      max = number.size - 1
      # get usages of nearest existing account by number
      (0..max).to_a.reverse.each do |i|
        n = number[0, i]
        items = Nomen::Account.where(fr_pcga: n)
        parent_accounts = Account.find_with_regexp(n)
        break if parent_accounts.any?
      end

      usages = if parent_accounts && parent_accounts.any?
                 parent_accounts.first.usages
               elsif items.any?
                 items.first.name
               end

      usages
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
        excepts << code if prefix =~ /^\^\d+$/
        normals << code if prefix =~ /^\-?\d+[CDX]?$/
      end
      conditions = ''
      if normals.any?
        conditions << '(' + normals.sort.collect do |c|
          "#{table}.number LIKE '#{c}%'"
        end.join(' OR ') + ')'
      end
      if excepts.any?
        conditions << ' AND NOT (' + excepts.sort.collect do |c|
          "#{table}.number LIKE '#{c}%'"
        end.join(' OR ') + ')'
      end
      conditions
    end
    alias find_with_regexp regexp_condition

    # Find all account matching with the regexp in a String
    # 123 will take all accounts 123*
    # ^456 will remove all accounts 456*
    def find_with_regexp(expr)
      where(regexp_condition(expr))
    end

    # Find or create an account with its name in accounting system if not exist in DB
    def find_or_import_from_nomenclature(usage)
      item = Nomen::Account.find(usage)
      raise ArgumentError, "The usage #{usage.inspect} is unknown" unless item
      account = find_in_nomenclature(usage)
      unless account
        account = create!(
          name: item.human_name,
          number: item.send(accounting_system),
          debtor: !!item.debtor,
          usages: item.name
        )
      end
      account
    end
    alias import_from_nomenclature find_or_import_from_nomenclature

    # Returns the name of the used accounting system
    # It takes the information in preferences
    def accounting_system
      Preference[:accounting_system]
    end

    def french_accounting_system?
      %w(fr_pcg82 fr_pcga).include?(accounting_system)
    end

    # Returns the name of the used accounting system
    # It takes the information in preferences
    def accounting_system=(name)
      unless item = Nomen::AccountingSystem[name]
        raise ArgumentError, "The accounting system #{name.inspect} is unknown."
      end
      Preference.set!(:accounting_system, item.name)
    end

    # Returns the human name of the accounting system
    def accounting_system_name(name = nil)
      Nomen::AccountingSystem[name || accounting_system].human_name
    end

    # Find.all available accounting systems in all languages
    def accounting_systems
      Nomen::AccountingSystem.all
    end

    # Load a accounting system
    def load_defaults
      transaction do
        # Destroy unused existing accounts
        find_each do |account|
          account.destroy if account.destroyable?
        end
        Nomen::Account.find_each do |item|
          find_or_import_from_nomenclature(item.name)
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
          if expr =~ /\-/
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
          if expr =~ /\-/
            start, finish = expr.split(/\-+/)[0..1]
            max = [start.length, finish.length].max
            conditions << "SUBSTR(#{table}.number, 1, #{max}) BETWEEN #{connection.quote(start.ljust(max, '0'))} AND #{connection.quote(finish.ljust(max, 'Z'))}"
          else
            conditions << "#{table}.number LIKE #{connection.quote(expr + '%%')}"
          end
        end
      end
      '(' + conditions.join(' OR ') + ')'
    end

    # Returns list of reconcilable prefixes defined in preferences
    def reconcilable_prefixes
      [:clients, :suppliers, :attorneys].collect do |mode|
        Nomen::Account[mode].send(accounting_system).to_s
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
      Nomen::Account[i]
    end.compact
  end

  # Check if the account is a third account and therefore returns if it should be reconcilable
  def reconcilableable?
    (number.to_s.match(self.class.reconcilable_regexp) ? true : false)
  end

  def reconcilable_entry_items(period, started_at, stopped_at)
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

    accounts.each do |account|
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

      if account.number =~ /^(6|7)/
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
        if account[:number].to_s =~ /^12/
          account[:debit] += res_debit
          account[:credit] += res_credit
          account[:balance] += res_balance # solde
        end
      elsif res_balance < 0
        if account[:number].to_s =~ /^129/
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

      next if journal_entry_items.empty?
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

    ledger.compact
  end
end
