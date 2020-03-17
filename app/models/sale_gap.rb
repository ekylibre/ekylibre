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
# == Table: gaps
#
#  accounted_at     :datetime
#  affair_id        :integer
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  direction        :string           not null
#  entity_id        :integer          not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  number           :string           not null
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  printed_at       :datetime         not null
#  type             :string
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class SaleGap < Gap
  belongs_to :client, foreign_key: :entity_id, class_name: 'Entity'

  alias_attribute :third_id, :entity_id

  acts_as_affairable :client, good: :profit?, debit: :loss?, class_name: 'SaleAffair'

  bookkeep do |b|
    b.journal_entry(Journal.used_for_gaps!(currency: currency),
                    printed_on: printed_on, unless: amount.zero?) do |entry|
      label = tc(:bookkeep, resource: direction.l, number: number, client: client.full_name)
      entry.add_debit(label, client.account(:client).id, relative_amount, as: :client)
      items.each do |item|
        entry.add_credit(label, Account.find_or_import_from_nomenclature(profit? ? :other_usual_running_profits : :other_usual_running_expenses), item.relative_pretax_amount, resource: item, as: :item_product)
        entry.add_credit(label, profit? ? item.tax.collect_account_id : item.tax.deduction_account_id, item.relative_taxes_amount, tax: item.tax, pretax_amount: item.relative_pretax_amount, resource: item, as: :item_tax)
      end
    end
  end
end
