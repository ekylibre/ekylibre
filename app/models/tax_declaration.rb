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
# == Table: tax_declarations
#
#  accounted_at      :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  description       :text
#  financial_year_id :integer          not null
#  id                :integer          not null, primary key
#  invoiced_on       :date
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  mode              :string           not null
#  number            :string
#  reference_number  :string
#  responsible_id    :integer
#  started_on        :date             not null
#  state             :string
#  stopped_on        :date             not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class TaxDeclaration < Ekylibre::Record::Base
  include Attachable
  attr_readonly :currency
  refers_to :currency
  enumerize :mode, in: %i[debit payment], predicates: true
  belongs_to :financial_year
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :responsible, class_name: 'User'
  # belongs_to :tax_office, class_name: 'Entity'
  has_many :items, class_name: 'TaxDeclarationItem', dependent: :destroy, inverse_of: :tax_declaration
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :currency, :financial_year, :mode, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :invoiced_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :number, :reference_number, :state, length: { maximum: 500 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(tax_declaration) { tax_declaration.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]
  validates :number, uniqueness: true
  validates_associated :items

  acts_as_numbered
  # acts_as_affairable :tax_office
  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:tax_id].blank? && item[:tax].blank? }, allow_destroy: true

  delegate :tax_declaration_mode, :tax_declaration_frequency,
           :tax_declaration_mode_payment?, :tax_declaration_mode_debit?,
           to: :financial_year

  protect on: :update do
    old = old_record
    (old && old.sent?) || (old.validated? && draft?)
  end

  protect on: :destroy do
    old = old_record
    old.sent?
  end

  state_machine :state, initial: :draft do
    state :draft
    state :validated
    state :sent
    event :propose do
      transition draft: :validated, if: :has_content?
    end
    event :confirm do
      transition validated: :sent, if: :has_content?
    end
  end

  before_validation(on: :create) do
    self.state ||= :draft
    if financial_year
      self.mode = financial_year.tax_declaration_mode
      self.currency = financial_year.currency
      # if tax_declarations exists for current financial_year, then get the last to compute started_on
      self.started_on ||= financial_year.next_tax_declaration_on
      # raise self.started_on.inspect
      # anyway, stopped_on is started_on + tax_declaration_frequency_duration
      if started_on
        self.stopped_on ||= financial_year.tax_declaration_stopped_on(started_on)
        self.stopped_on = financial_year.stopped_on if self.stopped_on > financial_year.stopped_on
      end
    end
    self.invoiced_on ||= self.stopped_on
  end

  before_validation do
    self.created_at ||= Time.zone.now
  end

  validate do
    if self.started_on && stopped_on
      if stopped_on <= self.started_on
        errors.add(:stopped_on, :posterior, to: self.started_on.l)
      end
      if others.any?
        errors.add(:started_on, :overlap) if others.where('? BETWEEN started_on AND stopped_on', started_on).any?
        errors.add(:stopped_on, :overlap) if others.where('? BETWEEN started_on AND stopped_on', stopped_on).any?
      end
    end
  end

  after_create :compute!, if: :draft?

  def destroy
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("DELETE FROM tax_declaration_item_parts tdip USING tax_declaration_items tdi WHERE tdip.tax_declaration_item_id = tdi.id AND tdi.tax_declaration_id = #{id}")
      ActiveRecord::Base.connection.execute("DELETE FROM tax_declaration_items WHERE tax_declaration_id = #{id}")
      items.reload
      super
    end
  end

  def has_content?
    items.any?
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(self.state.to_sym).human_name
  end

  # This callback bookkeeps the sale depending on its state
  bookkeep do |b|
    journal = Journal.used_for_tax_declarations!(currency: currency)
    b.journal_entry(journal, printed_on: invoiced_on, if: (has_content? && (validated? || sent?))) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, number: number, started_on: started_on.l, stopped_on: stopped_on.l)
      items.each do |item|
        entry.add_debit(label, item.tax.collect_account.id, item.collected_tax_amount.round(2), tax: item.tax, resource: item, as: :collect) unless item.collected_tax_amount.zero?
        entry.add_credit(label, item.tax.deduction_account.id, item.deductible_tax_amount.round(2), tax: item.tax, resource: item, as: :deduction) unless item.deductible_tax_amount.zero?
        entry.add_credit(label, item.tax.fixed_asset_deduction_account.id, item.fixed_asset_deductible_tax_amount.round(2), tax: item.tax, resource: item, as: :fixed_asset_deduction) unless item.fixed_asset_deductible_tax_amount.zero?
        entry.add_credit(label, item.tax.intracommunity_payable_account.id, item.intracommunity_payable_tax_amount.round(2), tax: item.tax, resource: item, as: :intracommunity_payable) unless item.intracommunity_payable_tax_amount.zero?
      end
      unless global_balance.zero?
        if global_balance < 0
          account = Account.find_or_import_from_nomenclature(:report_vat_credit)
          # account = Account.find_or_create_by!(number: '44567', usages: :deductible_vat)
        elsif global_balance > 0
          account = Account.find_or_import_from_nomenclature(:vat_to_pay)
          # account = Account.find_or_create_by!(number: '44551', usages: :collected_vat)
        end
        entry.add_credit(label, account, global_balance, as: :balance)
      end
    end
  end

  def dealt_at
    (validated? ? invoiced_on : stopped_on? ? self.created_at : Time.zone.now)
  end

  def status
    return :go if sent?
    return :caution if validated?
    :stop
  end

  def human_status
    I18n.t("tooltips.models.tax_declaration.#{status}")
  end


  # FIXME: Too french
  def undeclared_tax_journal_entry_items
    JournalEntryItem
      .includes(:entry, :tax_declaration_item_parts, account: %i[collected_taxes paid_taxes])
      .order('journal_entries.printed_on, accounts.number')
      .where(printed_on: financial_year.started_on..stopped_on)
      .where('tax_declaration_item_parts.id IS NULL')
      .where.not(resource_type: 'TaxDeclarationItem')
      .where('accounts.number LIKE ?', '445%')
  end

  def out_of_range_tax_journal_entry_items
    journal_entry_item_ids = TaxDeclarationItemPart.select('journal_entry_item_id').where(tax_declaration_item_id: items.select('id'))
    JournalEntryItem
      .includes(:entry)
      .order('journal_entries.printed_on')
      .where('journal_entry_items.printed_on < ?', started_on)
      .where(id: journal_entry_item_ids)
  end

  # FIXME: Too french
  def unidentified_revenues_journal_entry_items
    JournalEntryItem.includes(:entry, :account).order('journal_entries.printed_on, accounts.number').where(printed_on: started_on..stopped_on).where('accounts.number LIKE ? AND journal_entry_items.resource_id is null', '7%')
  end

  # FIXME: Too french
  def unidentified_expenses_journal_entry_items
    JournalEntryItem.includes(:entry, :account).order('journal_entries.printed_on, accounts.number').where(printed_on: started_on..stopped_on).where('accounts.number LIKE ? AND journal_entry_items.resource_id is null', '6%')
  end

  def deductible_tax_amount_balance
    items.map(&:deductible_tax_amount).compact.sum
  end

  def collected_tax_amount_balance
    items.map(&:collected_tax_amount).compact.sum
  end

  def global_balance
    items.sum(:balance_tax_amount).round(2)
  end

  # Compute tax declaration with its items
  def compute!
    set_entry_items_tax_modes

    taxes = Tax.order(:name)
    # Removes unwanted tax declaration item
    items.where.not(tax: taxes).find_each(&:destroy)
    # Create or update other items
    taxes.find_each do |tax|
      items.find_or_initialize_by(tax: tax).compute!
    end
  end

  private

  def set_entry_items_tax_modes
    all = JournalEntryItem
          .where.not(tax_id: nil)
          .where('printed_on <= ?', stopped_on)
          .where(tax_declaration_mode: nil)
    set_non_purchase_entry_items_tax_modes all.where.not(resource_type: 'PurchaseItem')
    set_purchase_entry_items_tax_modes all.where(resource_type: 'PurchaseItem')
  end

  def set_non_purchase_entry_items_tax_modes(entry_items)
    entry_items.update_all tax_declaration_mode: financial_year.tax_declaration_mode
  end

  def set_purchase_entry_items_tax_modes(entry_items)
    { 'at_invoicing' => 'debit', 'at_paying' => 'payment' }.each do |tax_payability, declaration_mode|
      entry_items
        .joins('INNER JOIN purchase_items pi ON pi.id = journal_entry_items.resource_id')
        .joins('INNER JOIN purchases p ON p.id = pi.purchase_id')
        .where('p.tax_payability' => tax_payability)
        .update_all tax_declaration_mode: declaration_mode
    end
  end
end
