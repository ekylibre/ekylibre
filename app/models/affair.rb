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
# == Table: affairs
#
#  accounted_at           :datetime
#  cash_session_id        :integer
#  closed                 :boolean          default(FALSE), not null
#  closed_at              :datetime
#  created_at             :datetime         not null
#  creator_id             :integer
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  dead_line_at           :datetime
#  deals_count            :integer          default(0), not null
#  debit                  :decimal(19, 4)   default(0.0), not null
#  description            :text
#  id                     :integer          not null, primary key
#  journal_entry_id       :integer
#  letter                 :string
#  lock_version           :integer          default(0), not null
#  name                   :string
#  number                 :string
#  origin                 :string
#  pretax_amount          :decimal(19, 4)   default(0.0)
#  probability_percentage :decimal(19, 4)   default(0.0)
#  responsible_id         :integer
#  state                  :string
#  third_id               :integer          not null
#  type                   :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#

# Where to put amounts. The point of view is third's one.
#       Deal      |  Debit  |  Credit |
# Sale            |    X    |         |
# SaleCredit      |         |    X    |
# SaleGap         | Profit! |  Loss!  |
# Payslip         |         |    X    |
# Purchase        |         |    X    |
# PurchaseCredit  |         |         |
# PurchaseGap     | Profit! |  Loss!  |
# OutgoingPayment |    X    |         |
# IncomingPayment |         |    X    |
# Regularization  |    ?    |    ?    |
#
class Affair < Ekylibre::Record::Base
  include Attachable
  refers_to :currency
  belongs_to :cash_session
  belongs_to :journal_entry
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  belongs_to :third, class_name: 'Entity'
  # FIXME: Gap#affair_id MUST NOT be mandatory
  has_many :events
  has_many :gaps,              inverse_of: :affair # , dependent: :delete_all
  has_many :incoming_payments, inverse_of: :affair, dependent: :nullify
  has_many :outgoing_payments, inverse_of: :affair, dependent: :nullify
  has_many :payslips,          inverse_of: :affair, dependent: :nullify
  has_many :purchase_invoices, inverse_of: :affair, dependent: :nullify
  has_many :sales,             inverse_of: :affair, dependent: :nullify
  has_many :regularizations,   inverse_of: :affair, dependent: :destroy
  has_many :debt_transfers, inverse_of: :affair, dependent: :nullify
  has_many :debt_regularizations, inverse_of: :debt_transfer_affair, foreign_key: :debt_transfer_affair_id, class_name: 'DebtTransfer', dependent: :nullify

  # has_many :tax_declarations,  inverse_of: :affair, dependent: :nullify
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :closed_at, :dead_line_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :closed, inclusion: { in: [true, false] }
  validates :credit, :debit, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :third, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :letter, :name, :origin, :state, length: { maximum: 500 }, allow_blank: true
  validates :number, uniqueness: true, length: { maximum: 500 }, allow_blank: true
  validates :pretax_amount, :probability_percentage, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }

  scope :closeds, -> { where(closed: true) }
  scope :opened, -> { where(closed: false) }

  before_validation do
    self.debit = 0
    self.credit = 0
    self.deals_count = deals.count
    deals.each do |deal|
      self.debit += deal.deal_debit_amount
      self.credit += deal.deal_credit_amount
    end
    # Check state
    if self.credit == self.debit # and self.debit != 0
      self.closed_at = Time.zone.now unless closed
      self.closed = true
    else
      self.closed = false
      self.closed_at = nil
    end
  end

  before_save :letter_journal_entries

  def number
    "A#{id.to_s.rjust(7, '0')}"
  end

  def work_name
    number.to_s
  end

  # Returns the first deal number for the given type as deal work name.
  # FIXME: Not sure that's a good method. Why the first deal number is used as the
  #        "deal work name".
  def deal_work_name
    d = deals_of_type(self.class.deal_class).first
    return d.number if d
    nil
  end

  class << self
    # Find or create journal for affairs
    def journal
      unless j = Journal.used_for_affairs
        if j = Journal.where(nature: :various).order(id: :desc).first
          j.update_column(:used_for_affairs, true)
        else
          j = Journal.create!(name: Affair.model_name.human, nature: :various, used_for_affairs: true)
        end
      end
      j
    end

    # Returns types of accepted deals
    def affairable_types
      @affairable_types ||= %w[SaleGap PurchaseGap Sale PurchaseInvoice Payslip IncomingPayment OutgoingPayment Regularization DebtTransfer].freeze
    end

    # Removes empty affairs in the whole table
    def clean_deads
      query = "journal_entry_id NOT IN (SELECT id FROM #{connection.quote_table_name(:journal_entries)})"
      query << self.class.affairable_types.collect do |type|
        model = type.constantize
        " AND id NOT IN (SELECT #{model.reflect_on_association(:affair).foreign_key} FROM #{connection.quote_table_name(model.table_name)})"
      end.join
      where(query).delete_all
    end

    # Returns heterogen list of deals of the affair
    def generate_deals_method
      code  = "def deals\n"
      array = affairable_types.collect do |class_name|
        "#{class_name}.where(affair_id: self.id).to_a"
      end.join(' + ')
      code << "  return (#{array}).compact.sort do |a, b|\n"
      code << "    a.dealt_at <=> b.dealt_at\n"
      code << "  end\n"
      code << "end\n"
      class_eval code
    end
  end

  generate_deals_method

  # Returns the remaining balance of the affair
  # Positive result is a profit
  # A contrario, negative result is a loss
  def balance
    self.credit - self.debit
  end

  def absorb!(other)
    unless other.is_a?(Affair)
      raise "#{other.class.name} (ID=#{other.id}) cannot be merged in Affair"
    end
    return self if self == other
    if other.currency != currency
      raise ArgumentError, "The currency (#{currency}) is different of the affair currency(#{other.currency})"
    end
    Ekylibre::Record::Base.transaction do
      other.deals.each do |deal|
        deal.update_columns(affair_id: id)
        deal.reload
      end
      refresh!
      other.destroy!
    end
    self
  end

  def extract!(deal)
    unless deals.include?(deal)
      raise ArgumentError, 'Given deal is not one of the affair'
    end
    Ekylibre::Record::Base.transaction do
      affair = self.class.create!(currency: deal.currency, third: deal.deal_third)
      update_column(:affair_id, affair.id)
      affair.refresh!
      refresh!
      destroy! if deals_count.zero?
    end
  end

  def third_credit_balance
    JournalEntryItem.where(entry: deals.map(&:journal_entry), account: third_account).sum('real_credit - real_debit')
  end

  # Check if debit is equal to credit
  def unbalanced?
    self.debit != self.credit
  end

  # Check if debit is equal to credit
  def balanced?
    !unbalanced?
  end

  def status
    (closed? ? :go : deals_count > 1 ? :caution : :stop)
  end

  # Reload and save! affair to force counts and sums computation
  def refresh!
    reload
    save!
  end

  # Returns if the affair is bad for us...
  def losing?
    self.debit > self.credit
  end

  def finishable?
    unbalanced? && gap_class && !multi_thirds?
  end

  def debt_transferable?
    # unbalanced
    !closed && unbalanced?
  end

  # Adds a gap to close the affair
  #
  # Basically we calculate the gap between the debit and credit
  # for each third then we create GapItems for each VAT % present
  # in the biggest value between debit and credit.
  # Each of those holds a value equal to (VATed amount / total) * gap
  # so the amounts amounts taxed at each VAT %s in the gap are
  # proportional to the VAT %s amounts in the debit/credit.
  def finish
    return false if balance.zero?
    raise 'Cannot finish anymore multi-thirds affairs' if multi_thirds?
    precision = Nomen::Currency.find(currency).precision
    self.class.transaction do
      # Get all VAT-specified deals
      deals_amount = deals.map do |deal|
        %i[debit credit].map do |mode|
          # Get the items of the deal with their VAT %
          # then add 0% VAT to untaxed deals
          deal.deal_taxes(mode)
              .each { |am| am[:tax] ||= Tax.used_for_untaxed_deals }
        end
      end

      # Extract the debit ones from the credit ones / vice versa
      debit_deals = deals_amount.map(&:first).flatten
      credit_deals = deals_amount.map(&:last).flatten

      # Group the same-VAT-ed amounts.
      # Groups amounts by tax, sums the amounts, and converts back to hash
      grouped_debit = debit_deals
                      .group_by { |d| d[:tax] }
                      .map { |tax, pairs| [tax, pairs.map { |p| p[:amount] }.sum] }
                      .to_h

      # Groups amounts by tax, sums the amounts, and converts back to hash
      grouped_credit = credit_deals
                       .group_by { |c| c[:tax] }
                       .map { |tax, pairs| [tax, pairs.map { |p| p[:amount] }.sum] }
                       .to_h

      total_debit = grouped_debit.values.sum
      total_credit = grouped_credit.values.sum

      gap_amount = (total_debit - total_credit).abs

      # Select which will be used as a reference for VAT % ratios on gap
      bigger_total = [total_debit, total_credit].max

      # Gap is always on the lesser column.
      gap_is_credit = bigger_total == total_debit

      bigger_deal_set = gap_is_credit ? grouped_debit : grouped_credit

      # Construct a GapItem per VAT % in the debit/credit
      gap_items = bigger_deal_set.map do |tax, taxed_amount|
        # Calculate percentage of the column taxed at `tax`
        percentage_at_vat = taxed_amount / bigger_total
        # Apply that percentage to the gap to get a proportional amount
        taxed_amount_in_gap = percentage_at_vat * gap_amount
        # Get that amount +/- depending if we're crediting or debiting
        # taxed_amount_in_gap *= -1 unless gap_is_credit
        # Get the pre-tax value
        pretaxed_amount_in_gap = tax.pretax_amount_of(taxed_amount_in_gap)

        GapItem.new(
          currency: currency,
          tax: tax,
          amount: taxed_amount_in_gap.round(precision),
          pretax_amount: pretaxed_amount_in_gap.round(precision)
        )
      end

      # TODO: Check that rounds fit exactly wanted amount

      gap_class.create!(
        affair: self,
        amount: gap_amount,
        currency: currency,
        entity: third,
        direction: (!gap_is_credit ? :profit : :loss),
        items: gap_items
      )
      refresh!
    end
    true
  end

  def gap_class
    nil
  end

  def self.deal_class
    name.gsub(/Affair$/, '').constantize
  end

  def originator
    deals.first
  end

  # Returns deals of the given third
  def deals_of(third)
    deals.select do |deal|
      deal.deal_third == third
    end
  end

  def deals_of_type(klass)
    if klass.is_a?(Class)
      klass.where(affair_id: id)
    else
      klass.constantize.where(affair_id: id)
    end
  end

  # Returns all associated thirds of the affair
  def thirds
    deals.map(&:deal_third).uniq
  end

  # Permit to attach a deal from affair
  def attach(deal)
    deal.deal_with!(self)
  end

  # Permit to detach a deal from affair
  def detach(deal)
    deal.undeal!(self)
  end

  def reload_gaps
    return if gaps.none?
    gaps.each { |g| g.undeal! self }
    finish
  end

  # Returns the currency precision to use in affair
  def currency_precision(default = 2)
    FinancialYear.at.currency_precision || default
  end

  def third_role
    raise NotImplementedError
  end

  def letterable?
    !unletterable?
  end

  def unletterable?
    multi_thirds?
  end

  def lettered?
    letter?
  end

  def letter_journal_entries
    letter_journal_entries! if letterable?
  end

  def third_account
    third.account(third_role)
  end
  alias letterable_account third_account

  def letterable_journal_entry_items
    JournalEntryItem.where(account: letterable_account, entry: deals.map(&:journal_entry))
  end

  # Returns true if a part of items are already lettered by outside
  def journal_entry_items_already_lettered?
    letters = letterable_journal_entry_items.pluck(:letter).map { |letter| letter.delete('*') }
    if (letter? && letters.detect { |x| x != letter }) ||
       (!letter? && letters.detect(&:present?))
      return true
    end
    false
  end

  # Returns true if a part of items are already lettered by outside
  def journal_entry_items_balanced?
    letterable_journal_entry_items.sum('debit - credit').zero?
  end

  # Returns true if a part of items are already lettered by outside
  def journal_entry_items_unbalanced?
    !journal_entry_items_balanced?
  end

  # Returns true if debit/credit are the same for third in journal entry items
  def match_with_accountancy?
    letterable_journal_entry_items.sum(:real_debit) == credit &&
      letterable_journal_entry_items.sum(:real_credit) == debit
  end

  # Returns true if many thirds are involved in this affair
  def multi_thirds?
    thirds.count > 1
  end

  # Adds a letter on journal
  def letter_journal_entries!
    journal_entry_items = letterable_journal_entry_items
    account = letterable_account

    # Update letters
    account.unmark(letter) if journal_entry_items.any?
    self.letter = nil if letter.blank?
    self.letter = account.mark!(journal_entry_items.pluck(:id), letter)
    true
  end
end
