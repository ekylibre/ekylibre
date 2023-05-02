# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: purchases
#
#  accounted_at                             :datetime
#  affair_id                                :integer(4)
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  command_mode                             :string
#  confirmed_at                             :datetime
#  contract_id                              :integer(4)
#  created_at                               :datetime         not null
#  creator_id                               :integer(4)
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer(4)
#  description                              :text
#  estimate_reception_date                  :datetime
#  id                                       :integer(4)       not null, primary key
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer(4)
#  lock_version                             :integer(4)       default(0), not null
#  nature_id                                :integer(4)
#  number                                   :string           not null
#  ordered_at                               :datetime
#  payment_at                               :datetime
#  payment_delay                            :string
#  planned_at                               :datetime
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer(4)
#  reconciliation_state                     :string
#  reference_number                         :string
#  responsible_id                           :integer(4)
#  state                                    :string           not null
#  supplier_id                              :integer(4)       not null
#  tax_payability                           :string           not null
#  type                                     :string
#  undelivered_invoice_journal_entry_id     :integer(4)
#  updated_at                               :datetime         not null
#  updater_id                               :integer(4)
#
require 'test_helper'

class PurchaseInvoiceTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
  test 'reconciliation_state is set correctly' do
    purchase_item = create :purchase_item, variant: ProductNatureVariant.find_by_number('00000071')
    reception_item = create :reception_item, purchase_invoice_item_id: purchase_item.id, variant: purchase_item.variant
    purchase_item.purchase.reload
    purchase_item.purchase.save!

    assert purchase_item.purchase.reconciliation_state.reconcile?
  end
end
