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
  has_many :parts, foreign_key: :tax_declaration_item_id, class_name: 'TaxDeclarationItemPart', dependent: :destroy, inverse_of: :tax_declaration_item
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
    self.balance_pretax_amount = collected_pretax_amount - (deductible_pretax_amount + fixed_asset_deductible_pretax_amount) # do not use intracommunity pretax as already in deductible
    self.balance_tax_amount = collected_tax_amount - (deductible_tax_amount + fixed_asset_deductible_tax_amount + intracommunity_payable_tax_amount)
  end

  def compute!
    raise 'Cannot compute item without its tax' unless tax
    ActiveRecord::Base.transaction do
      generate_parts
      compute_amounts
      save!
    end
  end

  private

  def generate_parts
    parts.clear
    generate_debit_parts
    generate_payment_parts
  end

  def generate_debit_parts
    entry_items = JournalEntryItem
                  .where(financial_year_id: tax_declaration.financial_year_id)
                  .where('printed_on <= ? ', stopped_on)
                  .where(tax_declaration_mode: 'debit')
                  .where(tax: tax)
                  .where.not(resource_type: 'TaxDeclarationItem')
                  .where.not(id: TaxDeclarationItemPart.select(:journal_entry_item_id))

    tax_account_ids_by_direction.each do |direction, account_id|
      balance =
        if direction == :collected
          'journal_entry_items.credit - journal_entry_items.debit'
        else
          'journal_entry_items.debit - journal_entry_items.credit'
        end

      select_sql = <<-SQL
        journal_entry_items.id AS journal_entry_item_id,
        journal_entry_items.account_id AS account_id,
        (#{balance}) AS tax_amount,
        (#{balance}) AS total_tax_amount,
        journal_entry_items.pretax_amount AS pretax_amount,
        journal_entry_items.pretax_amount AS total_pretax_amount
      SQL

      part_rows = entry_items.where(account_id: account_id).select(select_sql)
      part_rows.each do |row|
        parts.build(
          journal_entry_item_id: row.journal_entry_item_id,
          account_id: row.account_id,
          tax_amount: row.tax_amount,
          total_tax_amount: row.total_tax_amount,
          pretax_amount: row.pretax_amount,
          total_pretax_amount: row.total_pretax_amount,
          direction: direction
        )
      end
    end
  end

  def generate_payment_parts
    tax_account_ids_by_direction.each do |direction, account_id|
      generate_payments_parts_for_direction_and_account_id(direction, account_id)
    end
  end

  def generate_payments_parts_for_direction_and_account_id(direction, account_id)
    conditions_sql = <<-SQL
      jei.tax_declaration_mode = ?
      AND jei.tax_id = ?
      AND jei.account_id = ?
      AND jei.resource_type != ?
      AND jei.financial_year_id = ?
    SQL

    conditions_sql_values = [
      'payment',
      tax.id,
      account_id,
      'TaxDeclarationItem',
      tax_declaration.financial_year_id
    ]

    conditions = [conditions_sql] + conditions_sql_values

    if direction == :collected
      balance = 'jei.credit - jei.debit'
      total_balance = 'tjei.debit - tjei.credit'
      paid_balance = 'pjei.credit - pjei.debit'
    else
      balance = 'jei.debit - jei.credit'
      total_balance = 'tjei.credit - tjei.debit'
      paid_balance = 'pjei.debit - pjei.credit'
    end

    sql = <<-SQL
      SELECT     jei.id AS journal_entry_item_id,
                 jei.account_id AS account_id,
                 ROUND(((#{balance}) * SUM(#{paid_balance}) / total.balance), 2) - COALESCE(declared.tax_amount, 0) AS tax_amount,
                 (#{balance}) AS total_tax_amount,
                 ROUND((jei.pretax_amount * SUM(#{paid_balance}) / total.balance), 2) - COALESCE(declared.pretax_amount, 0) AS pretax_amount,
                 jei.pretax_amount AS total_pretax_amount
      FROM       journal_entry_items jei

      INNER JOIN journal_entry_items iljei ON
                   iljei.entry_id = jei.entry_id
                   AND LENGTH(TRIM(iljei.letter)) > 0

      INNER JOIN (
        SELECT tjei.account_id,
               tjei.letter,
               SUM(#{total_balance}) AS balance
        FROM   journal_entry_items tjei
        WHERE  tjei.printed_on <= '#{stopped_on}'
               AND EXISTS(
                 SELECT 1
                 FROM   journal_entry_items
                 WHERE  entry_id = tjei.entry_id
                        AND tax_id IS NOT NULL
               )
        GROUP BY account_id, letter
      ) AS total ON total.letter = iljei.letter AND total.account_id = iljei.account_id

      INNER JOIN journal_entry_items pjei ON
                   pjei.letter = iljei.letter
                   AND pjei.account_id = iljei.account_id
                   AND pjei.printed_on <= '#{stopped_on}'
                   AND NOT EXISTS(
                     SELECT 1
                     FROM   journal_entry_items
                     WHERE  entry_id = pjei.entry_id
                            AND tax_id IS NOT NULL
                   )

      LEFT JOIN (
        SELECT   journal_entry_item_id,
                 direction,
                 SUM(tax_amount) AS tax_amount,
                 SUM(pretax_amount) AS pretax_amount
        FROM     tax_declaration_item_parts
        GROUP BY journal_entry_item_id, direction
      ) AS declared ON declared.journal_entry_item_id = jei.id AND declared.direction = '#{direction}'

      WHERE #{TaxDeclarationItem.send(:sanitize_sql_for_conditions, conditions)}
      GROUP BY jei.id, total.balance, declared.tax_amount, declared.pretax_amount
      HAVING ROUND(((#{balance}) * SUM(#{paid_balance}) / total.balance), 2) - COALESCE(declared.tax_amount, 0) != 0.0
    SQL

    part_rows = ActiveRecord::Base.connection.execute(sql)
    part_rows.to_a.each do |part_attributes|
      parts.build part_attributes.merge direction: direction
    end
  end

  def compute_amounts
    directions.each do |direction|
      direction_parts = parts.select { |part| part.direction == direction }
      tax_amount = direction_parts.sum(&:tax_amount) || 0.0
      pretax_amount = direction_parts.sum(&:pretax_amount) || 0.0
      send "#{direction}_tax_amount=", tax_amount
      send "#{direction}_pretax_amount=", pretax_amount
    end
  end

  def tax_account_ids_by_direction
    return unless tax
    { deductible: tax.deduction_account_id,
      collected: tax.collect_account_id,
      fixed_asset_deductible: tax.fixed_asset_deduction_account_id,
      intracommunity_payable: tax.intracommunity_payable_account_id }
  end

  def directions
    return unless tax
    tax_account_ids_by_direction.keys
  end
end
