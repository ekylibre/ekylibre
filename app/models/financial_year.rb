# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: financial_years
#
#  accountant_id             :integer
#  closed                    :boolean          default(FALSE), not null
#  code                      :string           not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  currency_precision        :integer
#  custom_fields             :jsonb
#  id                        :integer          not null, primary key
#  last_journal_entry_id     :integer
#  lock_version              :integer          default(0), not null
#  started_on                :date             not null
#  stopped_on                :date             not null
#  tax_declaration_frequency :string
#  tax_declaration_mode      :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

class FinancialYear < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency
  refers_to :currency
  enumerize :tax_declaration_frequency, in: %i[monthly quaterly yearly none],
                                        default: :monthly, predicates: { prefix: true }
  enumerize :tax_declaration_mode, in: %i[debit payment none], default: :none, predicates: { prefix: true }
  belongs_to :last_journal_entry, class_name: 'JournalEntry'
  belongs_to :accountant, class_name: 'Entity'
  has_many :account_balances, dependent: :delete_all
  has_many :exchanges, class_name: 'FinancialYearExchange', dependent: :destroy
  has_many :fixed_asset_depreciations, dependent: :restrict_with_exception
  has_many :inventories, dependent: :restrict_with_exception
  has_many :journal_entries, dependent: :restrict_with_exception
  has_many :tax_declarations, dependent: :restrict_with_exception
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed, inclusion: { in: [true, false] }
  validates :code, presence: true, length: { maximum: 500 }
  validates :currency, :tax_declaration_mode, presence: true
  validates :currency_precision, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(financial_year) { financial_year.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]
  validates :currency, presence: true, length: { allow_nil: true, maximum: 3 }
  validates :code, uniqueness: true, length: { allow_nil: true, maximum: 20 }
  validates :tax_declaration_frequency, presence: { unless: :tax_declaration_mode_none? }

  # This order must be the natural order
  # It permit to find the first and the last financial year
  scope :closed, -> { where(closed: true).reorder(:started_on) }
  scope :opened, -> { where(closed: false).reorder(:started_on) }
  scope :closables, -> { where(closed: false).where('stopped_on < ?', Time.zone.now).reorder(:started_on).limit(1) }
  scope :with_tax_declaration, -> { where.not(tax_declaration_mode: :none) }
  scope :with_missing_tax_declaration, -> { where('id NOT IN (SELECT f.id FROM financial_years AS f JOIN tax_declarations AS d ON (f.stopped_on BETWEEN d.started_on AND d.stopped_on))') }

  protect on: :destroy do
    fixed_asset_depreciations.any? || tax_declarations.any? || journal_entries.any? ||
      inventories.any?
  end

  class << self
    def on(searched_on)
      year = where('? BETWEEN started_on AND stopped_on', searched_on).order(started_on: :desc).first
      return year if year
      born_on = Entity.of_company.born_on
      return nil if searched_on < born_on
      year = FinancialYear.where('stopped_on < ?', searched_on).order(stopped_on: :desc).first
      year ||= FinancialYear.create_with(stopped_on: (born_on >> 11).end_of_month).find_or_create_by!(started_on: born_on)
      year = year.find_or_create_next! while year.stopped_on < searched_on
      year
    end

    # Find or create if possible the requested financial year for the searched date
    def at(searched_at = Time.zone.now)
      on(searched_at.to_date)
    end
    alias ensure_exists_at! at

    def first_of_all
      reorder(:started_on).first
    end

    def current
      on(Time.zone.today)
    end

    def closable
      closables.first
    end

    # Returns the date of the last closure if any
    def last_closure
      if year = closed.reorder(started_on: :desc).first
        return year.stopped_on
      end
      nil
    end
  end

  before_validation do
    self.currency ||= Preference[:currency]
    if ref = Nomen::Currency.find(self.currency)
      self.currency_precision ||= ref.precision
    end
    # self.started_on = self.started_on.beginning_of_day if self.started_on
    self.stopped_on = (started_on + 11.months).end_of_month if stopped_on.blank? && started_on
    # self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    self.code = default_code if started_on && stopped_on && code.blank?
    code.upper!
    code.succ! while self.class.where(code: code).where.not(id: id || 0).any?
  end

  validate do
    unless stopped_on.blank? || started_on.blank?
      errors.add(:stopped_on, :end_of_month) unless stopped_on == stopped_on.end_of_month
      errors.add(:stopped_on, :posterior, to: started_on.l) unless started_on < stopped_on
      # If some financial years are already present
      if others.any?
        errors.add(:started_on, :overlap) if others.where('? BETWEEN started_on AND stopped_on', started_on).any?
        errors.add(:stopped_on, :overlap) if others.where('? BETWEEN started_on AND stopped_on', stopped_on).any?
      end
    end
    errors.add(:accountant, :frozen) if accountant_id_changed? && opened_exchange?
    errors.add(:started_on, :frozen) if started_on_changed? && exchanges.any?

    company = Entity.of_company
    unless company.nil?
      errors.add(:started_on, :on_or_after, restriction: company.born_on) if company.born_on > started_on
    end
  end

  def journal_entries(conditions = nil)
    entries = JournalEntry.where(printed_on: started_on..stopped_on)
    if conditions.present?
      ActiveSupport::Deprecation.warn('Use of conditions in FinancialYear#journal_entries is deprecated. Please use #where after instead.')
      entries = entries.where(conditions)
    end
    entries
  end

  def name
    code
  end

  def missing_tax_declaration?
    !tax_declaration_frequency_none? &&
      TaxDeclaration.where('? BETWEEN started_on AND stopped_on', stopped_on).empty?
  end

  def next_tax_declaration_on
    declarations = TaxDeclaration.where('stopped_on BETWEEN ? AND ?', started_on, stopped_on)
    if declarations.any?
      declarations.order(stopped_on: :desc).first.stopped_on + 1
    else
      started_on
    end
  end

  def tax_declaration_frequency_duration
    if tax_declaration_frequency_monthly?
      1.month
    elsif tax_declaration_frequency_quaterly?
      3.months
    elsif tax_declaration_frequency_yearly?
      12.months
    end
  end

  def tax_declaration_stopped_on(from_on)
    return nil if tax_declaration_frequency_none?
    end_on = (from_on + tax_declaration_frequency_duration).beginning_of_month - 1
    end_on = stopped_on if end_on > stopped_on
    end_on
  end

  def previous_codes_with_missing_tax_declaration
    FinancialYear.with_missing_tax_declaration
                 .where('financial_years.stopped_on < ?', stopped_on)
                 .order(:started_on)
                 .pluck(:code)
  end

  def previous_consecutives?
    years = FinancialYear.select(:started_on, :stopped_on).where('started_on <= ?', started_on).order(:started_on)
    years.each_cons(2).all? { |previous_year, year| year.started_on == previous_year.stopped_on + 1.day }
  end

  def default_code
    tc('code.' + (started_on.year != stopped_on.year ? 'double' : 'single'), first_year: started_on.year, second_year: stopped_on.year)
  end

  def closure_obstructions(noticed_on = nil)
    noticed_on ||= Time.zone.today
    list = []
    list << :financial_year_already_closed if closed
    list << :draft_journal_entries_are_present if journal_entries.where(state: :draft).any?
    list << :previous_financial_year_is_not_closed if previous && !previous.closed
    list << :unbalanced_journal_entries_are_present_in_year unless journal_entries.where('debit != credit').empty?
    list << :financial_year_is_not_past if stopped_on >= noticed_on
    list
  end

  # tests if the financial_year can be closed.
  def closable?(noticed_on = nil)
    list = closure_obstructions(noticed_on)
    list.empty?
  end

  def closures(noticed_on = nil)
    noticed_on ||= Time.zone.today
    array = []
    first_year = self.class.order('started_on').first
    if (first_year.nil? || first_year == self) && self.class.count <= 1
      date = started_on.end_of_month
      while date < noticed_on
        array << date
        date = (date + 1).end_of_month
      end
    else
      array << stopped_on
    end
    array
  end

  # When a financial year is closed,.all the matching journals are closed too.
  def close(to_close_on = nil, options = {})
    FinancialYearClose.new(self, to_close_on, options).execute
  end

  # this method returns the previous financial_year by default.
  def previous
    self.class.find_by(stopped_on: started_on - 1)
  end

  # this method returns the next financial_year by default.
  def next
    self.class.find_by(started_on: stopped_on + 1)
  end

  # Find or create the next financial year based on the date of the current
  def find_or_create_next!
    unless (year = self.next)
      year = self.class.create!(started_on: stopped_on + 1, stopped_on: stopped_on >> 12, currency: self.currency)
    end
    year
  end

  # Find or create the previous financial year based on the date of the current
  def find_or_create_previous!
    unless (year = previous)
      year = self.class.create!(started_on: started_on << 12, stopped_on: started_on - 1, currency: self.currency)
    end
    year
  end

  # See Journal.sum_entry_items
  def sum_entry_items(expression, options = {})
    options[:started_on] ||= started_on
    options[:stopped_on] ||= stopped_on
    Journal.sum_entry_items(expression, options)
  end

  # get the equation to compute from accountancy abacus
  def get_mandatory_line_calculation(document = :profit_and_loss_statement, line = nil)
    ac = Account.accounting_system
    source = Rails.root.join('config', 'accoutancy_mandatory_documents.yml')
    data = YAML.load_file(source).deep_symbolize_keys.stringify_keys if source.file?
    if data && ac && document && line
      data[ac.to_s][document][line] if data[ac.to_s] && data[ac.to_s][document]
    end
  end

  def sum_entry_items_with_mandatory_line(document = :profit_and_loss_statement, line = nil, options = {})
    # remove closure entries
    options[:unwanted_journal_nature] ||= [:closure] if document == :balance_sheet
    options[:unwanted_journal_nature] ||= %i[result closure]

    equation = get_mandatory_line_calculation(document, line) if line
    equation ? sum_entry_items(equation, options) : 0
  end

  # Computes the value of list of accounts in a String
  # 123 will take all accounts 123*
  # ^456 will remove all accounts 456*
  # 789X will compute the balance although result is negative
  def balance(accounts, credit = false)
    normals = ['(XD)']
    excepts = []
    negatives = []
    forceds = []
    accounts.strip.split(/\s*[\,\s]+\s*/).each do |prefix|
      code = prefix.gsub(/(^(\-|\^)|[CDX]+$)/, '')
      excepts << code if prefix =~ /^\^\d+$/
      negatives << code if prefix =~ /^\-\d+/
      forceds << code if prefix =~ /^\-?\d+[CDX]$/
      normals << code if prefix =~ /^\-?\d+[CDX]?$/
    end

    balance = FinancialYear.balance_expr(credit)
    if !forceds.empty? || !negatives.empty?
      forceds_and_negatives = forceds & negatives
      balance = 'CASE'
      balance << ' WHEN ' + forceds_and_negatives.sort.collect { |c| "a.number LIKE '#{c}%'" }.join(' OR ') + " THEN -#{FinancialYear.balance_expr(!credit, forced: true)}" unless forceds_and_negatives.empty?
      balance << ' WHEN ' + forceds.collect { |c| "a.number LIKE '#{c}%'" }.join(' OR ') + " THEN #{FinancialYear.balance_expr(credit, forced: true)}" unless forceds.empty?
      balance << ' WHEN ' + negatives.sort.collect { |c| "a.number LIKE '#{c}%'" }.join(' OR ') + " THEN -#{FinancialYear.balance_expr(!credit)}" unless negatives.empty?
      balance << " ELSE #{FinancialYear.balance_expr(credit)} END"
    end

    query = "SELECT sum(#{balance}) AS balance FROM #{AccountBalance.table_name} AS ab JOIN #{Account.table_name} AS a ON (a.id=ab.account_id) WHERE ab.financial_year_id=#{id}"
    query << ' AND (' + normals.sort.collect { |c| "a.number LIKE '#{c}%'" }.join(' OR ') + ')'
    query << ' AND NOT (' + excepts.sort.collect { |c| "a.number LIKE '#{c}%'" }.join(' OR ') + ')' unless excepts.empty?
    balance = ActiveRecord::Base.connection.select_value(query)
    (balance.blank? ? nil : balance.to_d)
  end

  # Computes and formats debit balance for an account regexp
  # Use I18n to produce string
  def debit_balance(accounts)
    if value = balance(accounts, false)
      return value.l(currency: self.currency)
    end
    nil
  end

  # Computes and formats credit balance for an account regexp
  # Use I18n to produce string
  def credit_balance(accounts)
    if value = balance(accounts, true)
      return value.l(currency: self.currency)
    end
    nil
  end

  def self.balance_expr(credit = false, options = {})
    columns = %i[debit credit]
    columns.reverse! if credit
    prefix = (options[:record] ? options.delete(:record).to_s + '.' : '') + 'local_'
    if options[:forced]
      return "(#{prefix}#{columns[0]} - #{prefix}#{columns[1]})"
    else
      return "(CASE WHEN #{prefix}#{columns[0]} > #{prefix}#{columns[1]} THEN #{prefix}#{columns[0]} - #{prefix}#{columns[1]} ELSE 0 END)"
    end
  end

  # Re-create all account_balances record for the financial year
  def compute_balances!
    results = ActiveRecord::Base.connection.select_all("SELECT account_id, sum(debit) AS debit, sum(credit) AS credit, count(id) AS count FROM #{JournalEntryItem.table_name} WHERE state != 'draft' AND printed_on BETWEEN #{self.class.connection.quote(started_on)} AND #{self.class.connection.quote(stopped_on)} GROUP BY account_id")
    account_balances.clear
    results.each do |result|
      account_balances.create!(
        account_id: result['account_id'].to_i,
        local_count: result['count'].to_i,
        local_credit: result['credit'].to_f,
        local_debit: result['debit'].to_f,
        currency: self.currency
      )
    end
    self
  end

  # Generate last journal entry with financial assets depreciations (optionnally)
  def generate_last_journal_entry(options = {})
    unless last_journal_entry
      create_last_journal_entry!(printed_on: stopped_on, journal_id: options[:journal_id])
    end

    # Empty journal entry
    last_journal_entry.items.clear

    if options[:fixed_assets_depreciations]
      for depreciation in fixed_asset_depreciations.includes(:fixed_asset)
        name = tc(:bookkeep, resource: FixedAsset.model_name.human, number: depreciation.fixed_asset.number, name: depreciation.fixed_asset.name, position: depreciation.position, total: depreciation.fixed_asset.depreciations.count)
        # Charges
        last_journal_entry.add_debit(name, depreciation.fixed_asset.expenses_account, depreciation.amount)
        # Allocation
        last_journal_entry.add_credit(name, depreciation.fixed_asset.allocation_account, depreciation.amount)
        depreciation.update_attributes(journal_entry_id: last_journal_entry.id)
      end
    end
    self
  end

  def can_create_exchange?
    accountant_with_booked_journal? && !opened_exchange?
  end

  def opened_exchange?
    exchanges.opened.any?
  end

  private

  def accountant_with_booked_journal?
    accountant && accountant.booked_journals.any?
  end

  # Filter account balances with given accounts and with non-null balance
  def account_balances_for(account_numbers)
    account_balances.joins(:account)
                    .where('local_balance != ?', 0)
                    .where('accounts.number ~ ?', "^(#{account_numbers.join('|')})")
                    .order('accounts.number')
  end
end
