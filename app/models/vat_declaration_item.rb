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
# == Table: vat_declaration_items
#
#  collected_vat_amount  :decimal(19, 4)
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string           not null
#  deductible_vat_amount :decimal(19, 4)
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  tax_id                :integer          not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#  vat_declaration_id    :integer          not null
#

class VatDeclarationItem < Ekylibre::Record::Base
  refers_to :currency
  belongs_to :tax
  belongs_to :vat_declaration
  has_many :journal_entries, foreign_key: :vat_declaration_item_id, class_name: 'JournalEntry', inverse_of: :vat_declaration_item
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :collected_vat_amount, :deductible_vat_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :currency, :tax, :vat_declaration, presence: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }

  delegate :currency, to: :vat_declaration, prefix: true

  before_validation(on: :create) do
    if vat_declaration
      self.currency = vat_declaration_currency
      if tax && tax.collect_account && tax.deduction_account
        self.deductible_vat_amount = tax.collect_account.journal_entry_items_calculate(:balance, vat_declaration.started_on.to_time, vat_declaration.stopped_on.to_time, :sum)
        self.collected_vat_amount = tax.deduction_account.journal_entry_items_calculate(:balance, vat_declaration.started_on.to_time, vat_declaration.stopped_on.to_time, :sum)
      end
    end
  end
  
  
  before_validation do
    if vat_declaration
      self.currency = vat_declaration_currency
    end
  end

end
