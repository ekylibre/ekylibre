# coding: utf-8

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
#  balance_pretax_amount                :decimal(19, 4)   default(0.0), not null
#  balance_tax_amount                   :decimal(19, 4)   default(0.0), not null
#  collected_pretax_amount              :decimal(19, 4)   default(0.0), not null
#  collected_tax_amount                 :decimal(19, 4)   default(0.0), not null
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string           not null
#  deductible_pretax_amount             :decimal(19, 4)   default(0.0), not null
#  deductible_tax_amount                :decimal(19, 4)   default(0.0), not null
#  fixed_asset_deductible_pretax_amount :decimal(19, 4)   default(0.0), not null
#  fixed_asset_deductible_tax_amount    :decimal(19, 4)   default(0.0), not null
#  id                                   :integer          not null, primary key
#  intracommunity_payable_pretax_amount :decimal(19, 4)   default(0.0), not null
#  intracommunity_payable_tax_amount    :decimal(19, 4)   default(0.0), not null
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
  has_many :journal_entry_items, foreign_key: :tax_declaration_item_id, class_name: 'JournalEntryItem', inverse_of: :tax_declaration_item, dependent: :nullify
  has_one :financial_year, through: :tax_declaration
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :balance_pretax_amount, :balance_tax_amount, :collected_pretax_amount, :collected_tax_amount, :deductible_pretax_amount, :deductible_tax_amount, :fixed_asset_deductible_pretax_amount, :fixed_asset_deductible_tax_amount, :intracommunity_payable_pretax_amount, :intracommunity_payable_tax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :tax, :tax_declaration, presence: true
  # ]VALIDATORS]

  delegate :tax_declaration_mode, :tax_declaration_frequency, :started_on, :stopped_on, to: :tax_declaration
  delegate :tax_declaration_mode_payment?, :tax_declaration_mode_debit?, to: :financial_year
  delegate :currency, to: :tax_declaration, prefix: true
  delegate :name, to: :tax, prefix: true

  before_validation do
    self.currency = tax_declaration_currency if tax_declaration
    self.balance_pretax_amount = collected_pretax_amount - (deductible_pretax_amount + fixed_asset_deductible_pretax_amount + intracommunity_payable_pretax_amount)
    self.balance_tax_amount = collected_tax_amount - (deductible_tax_amount + fixed_asset_deductible_tax_amount + intracommunity_payable_tax_amount)
  end

  def compute!
    raise 'Cannot compute item without its tax' unless tax
    if tax_declaration_mode_payment?
      compute_in_payment_mode!
    elsif tax_declaration_mode_debit?
      compute_in_debit_mode!
    else
      raise 'No declaration mode given'
    end
  end

  def compute_in_payment_mode!
    journal_entry_items = targeted_journal_entry_items(lettered: true)
    compute_with_journal_entry_items! journal_entry_items
  end

  def compute_in_debit_mode!
    journal_entry_items = targeted_journal_entry_items
    compute_with_journal_entry_items! journal_entry_items
  end

  def compute_with_journal_entry_items!(journal_entry_items)
    self.deductible_tax_amount = journal_entry_items.where(account: tax.deduction_account).sum('debit - credit')
    self.deductible_pretax_amount = journal_entry_items.where(account: tax.deduction_account).sum(:pretax_amount)
    self.fixed_asset_deductible_tax_amount = journal_entry_items.where(account: tax.fixed_asset_deduction_account).sum('debit - credit')
    self.fixed_asset_deductible_pretax_amount = journal_entry_items.where(account: tax.fixed_asset_deduction_account).sum(:pretax_amount)
    self.intracommunity_payable_tax_amount = journal_entry_items.where(account: tax.intracommunity_payable_account).sum('debit - credit')
    self.intracommunity_payable_pretax_amount = journal_entry_items.where(account: tax.intracommunity_payable_account).sum(:pretax_amount)
    self.collected_tax_amount = journal_entry_items.where(account: tax.collect_account).sum('credit - debit')
    self.collected_pretax_amount = journal_entry_items.where(account: tax.collect_account).sum(:pretax_amount)
    save!
    self.journal_entry_items.where(tax_declaration_item_id: id).update_all(tax_declaration_item_id: nil)
    journal_entry_items.update_all(tax_declaration_item_id: id)
  end

  protected

  def targeted_journal_entry_items(options = {})
    relation = JournalEntryItem.where(tax: tax)
                               .where(printed_on: started_on..stopped_on)
                               .where('tax_declaration_item_id IS NULL OR tax_declaration_item_id = ?', id || 0)
    if options[:lettered].is_a?(TrueClass)
      relation = relation.where(entry_id: JournalEntryItem.select(:entry_id).where('LENGTH(TRIM(letter)) > 0'))
    end
    relation
  end
end
