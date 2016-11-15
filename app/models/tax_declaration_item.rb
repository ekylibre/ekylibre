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
# == Table: tax_declaration_items
#
#  collected_pretax_amount              :decimal(19, 4)
#  collected_tax_amount                 :decimal(19, 4)
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string           not null
#  deductible_pretax_amount             :decimal(19, 4)
#  deductible_tax_amount                :decimal(19, 4)
#  fixed_asset_deductible_pretax_amount :decimal(19, 4)
#  fixed_asset_deductible_tax_amount    :decimal(19, 4)
#  id                                   :integer          not null, primary key
#  lock_version                         :integer          default(0), not null
#  tax_declaration_id                   :integer          not null
#  tax_id                               :integer          not null
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#

class TaxDeclarationItem < Ekylibre::Record::Base
  refers_to :currency
  belongs_to :tax
  belongs_to :tax_declaration, class_name: 'TaxDeclaration'
  has_many :journal_entry_items, foreign_key: :tax_declaration_item_id, class_name: 'JournalEntryItem', inverse_of: :tax_declaration_item
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :collected_pretax_amount, :collected_tax_amount, :deductible_pretax_amount, :deductible_tax_amount, :fixed_asset_deductible_pretax_amount, :fixed_asset_deductible_tax_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :currency, :tax, :tax_declaration, presence: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }

  delegate :vat_mode, :vat_period, :currency, to: :tax_declaration, prefix: true

  before_validation(on: :create) do
    if tax_declaration
      self.currency = tax_declaration_currency
      if tax && tax.collect_account && tax.deduction_account
        v = prefill
        self.deductible_vat_amount = v[:deductible_vat_amount]
        self.collected_vat_amount = v[:collected_vat_amount]
        self.deductible_pretax_amount = v[:deductible_pretax_amount]
        self.collected_pretax_amount = v[:collected_pretax_amount]
        self.fixed_asset_deductible_vat_amount ||= 0.0
      end
    end
  end

  before_validation do
    self.currency = tax_declaration_currency if tax_declaration
  end

  def balance
    collected_vat_amount - (deductible_vat_amount + fixed_asset_deductible_vat_amount)
  end

  def prefill(tax = self.tax)
    # vat declaration period
    started_at = tax_declaration.started_on.to_time
    stopped_at = tax_declaration.stopped_on.to_time

    attributes = {}

    # get journal entry (unmark_je) unmark for vat for the period
    unmark_je = JournalEntry.between(started_at, stopped_at).where(tax_declaration_id: nil)

    ## for debit mode & payment mode
    # get all vat unmark sales from the current period
    unmark_sales = Sale.where(journal_entry_id: unmark_je.pluck(:id).uniq)
    unmark_sale_items = SaleItem.where(sale_id: unmark_sales.pluck(:id).uniq)
    # get all vat unmark purchases from the current period
    unmark_purchases = Purchase.where(journal_entry_id: unmark_je.pluck(:id).uniq)
    unmark_purchase_items = PurchaseItem.where(purchase_id: unmark_purchases.pluck(:id).uniq)

    ## for payment mode
    # get all vat unmark incoming payment from the current period
    unmark_incoming_payments = IncomingPayment.where(journal_entry_id: unmark_je.pluck(:id).uniq)
    # get all vat unmark outgoing payment from the current period
    unmark_outgoing_payments = OutgoingPayment.where(journal_entry_id: unmark_je.pluck(:id).uniq)

    if tax_declaration_vat_mode == :payment

      ## case deductible_vat

      # get all purchase item link to unmark_outgoing_payments
      affair_ids = unmark_outgoing_payments.pluck(:affair_id).uniq

      # closed_affair_ids = Affair.where(id: affair_ids, closed: true).pluck(:id)

      purchase_ids_to_mark = Purchase.where(affair_id: affair_ids).pluck(:id).uniq

      all_taxes_purchase_items = PurchaseItem.where(purchase_id: purchase_ids_to_mark)
      purchase_items = all_taxes_purchase_items.where(tax_id: tax.id)

      purchase_item_ids_to_mark = purchase_items.pluck(:id)
      purchase_journal_entry_ids_to_mark = JournalEntry.where(id: Purchase.where(id: purchase_ids_to_mark).pluck(:journal_entry_id))
      deductible_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: purchase_journal_entry_ids_to_mark, tax_declaration_item_id: nil)
      fixed_asset_deduction_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: purchase_journal_entry_ids_to_mark, account_id: tax.fixed_asset_deduction_account.id).pluck(:id).uniq if tax.fixed_asset_deduction_account

      # compute ratio for the consider tax to know the ratio to apply to the outgoing payment global amount
      sum_tax = purchase_items.map(&:amount).compact.sum
      sum_all_tax = all_taxes_purchase_items.map(&:amount).compact.sum
      ratio = (sum_tax / sum_all_tax).to_f if sum_all_tax != 0.0

      deduction_base_amount = (unmark_outgoing_payments.map(&:amount).compact.sum * ratio) / (1 + (tax.amount / 100))
      deduction_tax_amount = deduction_base_amount * (tax.amount / 100)

      outgoing_payment_ids_to_mark = unmark_outgoing_payments.pluck(:id)
      outgoing_payment_journal_entry_ids_to_mark = JournalEntry.where(id: unmark_outgoing_payments.pluck(:journal_entry_id))

      ## case collected_vat

      # get all purchase item link to unmark_outgoing_payments
      affair_ids = unmark_incoming_payments.pluck(:affair_id).uniq

      # closed_affair_ids = Affair.where(id: affair_ids, closed: true).pluck(:id)

      sale_ids_to_mark = Sale.where(affair_id: affair_ids).pluck(:id).uniq

      all_taxes_sale_items = SaleItem.where(sale_id: sale_ids_to_mark)
      sale_items = all_taxes_sale_items.where(tax_id: tax.id)

      sale_item_ids_to_mark = sale_items.pluck(:id)
      sale_journal_entry_ids_to_mark = JournalEntry.where(id: Sale.where(id: sale_item_ids_to_mark).pluck(:journal_entry_id))
      collected_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: sale_journal_entry_ids_to_mark, tax_declaration_item_id: nil)
      fixed_asset_collected_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: sale_journal_entry_ids_to_mark, account_id: tax.fixed_asset_collect_account.id).pluck(:id).uniq if tax.fixed_asset_collect_account

      # compute ratio for the consider tax to know the ratio to apply to the outgoing payment global amount
      sale_sum_tax = sale_items.map(&:amount).compact.sum
      sale_sum_all_tax = all_taxes_sale_items.map(&:amount).compact.sum
      sale_ratio = (sale_sum_tax / sale_sum_all_tax).to_f if sale_sum_all_tax != 0.0

      collected_base_amount = (unmark_incoming_payments.map(&:amount).compact.sum * sale_ratio) / (1 + (tax.amount / 100))
      collected_tax_amount = collected_base_amount * (tax.amount / 100)

      incoming_payment_ids_to_mark = unmark_incoming_payments.pluck(:id)
      incoming_payment_journal_entry_ids_to_mark = JournalEntry.where(id: unmark_incoming_payments.pluck(:journal_entry_id))

      attributes = { collected_pretax_amount: collected_base_amount,
                     collected_vat_amount: collected_tax_amount,
                     sale_ids_to_mark: sale_ids_to_mark,
                     sale_item_ids_to_mark: sale_item_ids_to_mark,
                     sale_journal_entry_ids_to_mark: sale_journal_entry_ids_to_mark,
                     collected_tax_journal_entry_item_ids_to_mark: collected_tax_journal_entry_item_ids_to_mark,
                     fixed_asset_collected_tax_journal_entry_item_ids_to_mark: fixed_asset_collected_tax_journal_entry_item_ids_to_mark,
                     incoming_payment_ids_to_mark: incoming_payment_ids_to_mark,
                     incoming_payment_journal_entry_ids_to_mark: incoming_payment_journal_entry_ids_to_mark,
                     deductible_pretax_amount: deduction_base_amount,
                     deductible_vat_amount: deduction_tax_amount,
                     purchase_ids_to_mark: purchase_ids_to_mark,
                     purchase_item_ids_to_mark: purchase_item_ids_to_mark,
                     purchase_journal_entry_ids_to_mark: purchase_journal_entry_ids_to_mark,
                     deductible_tax_journal_entry_item_ids_to_mark: deductible_tax_journal_entry_item_ids_to_mark,
                     fixed_asset_deduction_tax_journal_entry_item_ids_to_mark: fixed_asset_deduction_tax_journal_entry_item_ids_to_mark,
                     outgoing_payment_ids_to_mark: outgoing_payment_ids_to_mark,
                     outgoing_payment_journal_entry_ids_to_mark: outgoing_payment_journal_entry_ids_to_mark }

    elsif tax_declaration_vat_mode == :debit

      #  mark with D1 (id of vat declaration) for purchase_ids_to_mark and purchase_journal_entry_ids_to_mark
      # mark with LD1 (id of vat declaration item) for purchase_item_ids_to_mark and deductible_tax_journal_entry_item_ids_to_mark

      ## case deductible_vat
      deduction_base_amount = unmark_purchase_items.where(tax_id: tax.id).sum(:pretax_amount)
      deduction_tax_amount = unmark_purchase_items.where(tax_id: tax.id).sum(:amount) - deduction_base_amount
      purchase_ids_to_mark = unmark_purchase_items.where(tax_id: tax.id).pluck(:purchase_id).uniq
      purchase_item_ids_to_mark = unmark_purchase_items.where(tax_id: tax.id).pluck(:id).uniq
      purchase_journal_entry_ids_to_mark = Purchase.where(id: purchase_ids_to_mark).pluck(:journal_entry_id).uniq
      deductible_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: purchase_journal_entry_ids_to_mark, account_id: tax.deduction_account.id).pluck(:id).uniq
      fixed_asset_deduction_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: purchase_journal_entry_ids_to_mark, account_id: tax.fixed_asset_deduction_account.id).pluck(:id).uniq if tax.fixed_asset_deduction_account

      # FIXME: what about manual line input directly in journal ?
      # unmark_jei.where(account_id: tax.deduction_account.id).pluck(:id).compact.uniq
      # tax.deduction_account.journal_entry_items_calculate(:balance, started_at, stopped_at, :sum)

      #  mark with D1 (id of vat declaration) for sale_ids_to_mark and sale_journal_entry_ids_to_mark
      # mark with LD1 (id of vat declaration item) for sale_item_ids_to_mark and collected_tax_journal_entry_item_ids_to_mark

      ## case collected_vat
      collected_base_amount = unmark_sale_items.where(tax_id: tax.id).sum(:pretax_amount)
      collected_tax_amount = unmark_sale_items.where(tax_id: tax.id).sum(:amount) - collected_base_amount
      sale_ids_to_mark = unmark_sale_items.where(tax_id: tax.id).pluck(:sale_id).uniq
      sale_item_ids_to_mark = unmark_sale_items.where(tax_id: tax.id).pluck(:id).uniq
      sale_journal_entry_ids_to_mark = Sale.where(id: sale_ids_to_mark).pluck(:journal_entry_id).uniq
      collected_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: sale_journal_entry_ids_to_mark, account_id: tax.collect_account.id).pluck(:id).uniq
      fixed_asset_collected_tax_journal_entry_item_ids_to_mark = JournalEntryItem.where(entry_id: sale_journal_entry_ids_to_mark, account_id: tax.fixed_asset_collect_account.id).pluck(:id).uniq if tax.fixed_asset_collect_account

      # FIXME: what about manual line input directly in journal ?
      # unmark_jei.where(account_id: tax.collected_account.id).pluck(:id).compact.uniq
      # tax.collected_account.journal_entry_items_calculate(:balance, started_at, stopped_at, :sum)

      attributes = { collected_pretax_amount: collected_base_amount,
                     collected_vat_amount: collected_tax_amount,
                     sale_ids_to_mark: sale_ids_to_mark,
                     sale_item_ids_to_mark: sale_item_ids_to_mark,
                     sale_journal_entry_ids_to_mark: sale_journal_entry_ids_to_mark,
                     collected_tax_journal_entry_item_ids_to_mark: collected_tax_journal_entry_item_ids_to_mark,
                     fixed_asset_collected_tax_journal_entry_item_ids_to_mark: fixed_asset_collected_tax_journal_entry_item_ids_to_mark,
                     deductible_pretax_amount: deduction_base_amount,
                     deductible_vat_amount: deduction_tax_amount,
                     purchase_ids_to_mark: purchase_ids_to_mark,
                     purchase_item_ids_to_mark: purchase_item_ids_to_mark,
                     purchase_journal_entry_ids_to_mark: purchase_journal_entry_ids_to_mark,
                     deductible_tax_journal_entry_item_ids_to_mark: deductible_tax_journal_entry_item_ids_to_mark,
                     fixed_asset_deduction_tax_journal_entry_item_ids_to_mark: fixed_asset_deduction_tax_journal_entry_item_ids_to_mark }
    end

    attributes
  end
end
