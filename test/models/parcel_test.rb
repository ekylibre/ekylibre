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
# == Table: parcels
#
#  accounted_at                         :datetime
#  address_id                           :integer(4)
#  contract_id                          :integer(4)
#  created_at                           :datetime         not null
#  creator_id                           :integer(4)
#  currency                             :string
#  custom_fields                        :jsonb
#  delivery_id                          :integer(4)
#  delivery_mode                        :string
#  given_at                             :datetime
#  id                                   :integer(4)       not null, primary key
#  in_preparation_at                    :datetime
#  intervention_id                      :integer(4)
#  journal_entry_id                     :integer(4)
#  late_delivery                        :boolean
#  lock_version                         :integer(4)       default(0), not null
#  nature                               :string           not null
#  number                               :string           not null
#  ordered_at                           :datetime
#  planned_at                           :datetime         not null
#  position                             :integer(4)
#  prepared_at                          :datetime
#  pretax_amount                        :decimal(19, 4)   default(0.0), not null
#  purchase_id                          :integer(4)
#  recipient_id                         :integer(4)
#  reconciliation_state                 :string
#  reference_number                     :string
#  remain_owner                         :boolean          default(FALSE), not null
#  responsible_id                       :integer(4)
#  sale_id                              :integer(4)
#  sale_nature_id                       :integer(4)
#  sender_id                            :integer(4)
#  separated_stock                      :boolean
#  state                                :string           not null
#  storage_id                           :integer(4)
#  transporter_id                       :integer(4)
#  type                                 :string
#  undelivered_invoice_journal_entry_id :integer(4)
#  updated_at                           :datetime         not null
#  updater_id                           :integer(4)
#  with_delivery                        :boolean          default(FALSE), not null
#

require 'test_helper'

class ParcelTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
end
