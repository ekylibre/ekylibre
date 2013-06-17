# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: entities
#
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string(32)
#  attorney                  :boolean          not null
#  attorney_account_id       :integer
#  authorized_payments_count :integer
#  born_on                   :date
#  client                    :boolean          not null
#  client_account_id         :integer
#  country                   :string(2)
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string(255)      not null
#  dead_on                   :date
#  deliveries_conditions     :string(60)
#  description               :text
#  discount_percentage       :decimal(19, 4)
#  first_met_on              :date
#  first_name                :string(255)
#  full_name                 :string(255)      not null
#  id                        :integer          not null, primary key
#  invoices_count            :integer
#  language                  :string(3)        default("???"), not null
#  last_name                 :string(255)      not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          not null
#  nature                    :string(255)      not null
#  number                    :string(64)
#  of_company                :boolean          not null
#  origin                    :string(255)
#  payment_delay             :string(255)
#  payment_mode_id           :integer
#  picture_content_type      :string(255)
#  picture_file_name         :string(255)
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  proposer_id               :integer
#  prospect                  :boolean          not null
#  reduction_percentage      :decimal(19, 4)
#  reminder_submissive       :boolean          not null
#  responsible_id            :integer
#  sale_price_listing_id     :integer
#  siren                     :string(9)
#  soundex                   :string(4)
#  supplier                  :boolean          not null
#  supplier_account_id       :integer
#  transporter               :boolean          not null
#  type                      :string(255)
#  updated_at                :datetime         not null
#  updater_id                :integer
#  vat_number                :string(15)
#  vat_submissive            :boolean          default(TRUE), not null
#  webpass                   :string(255)
#
class LegalEntity < Entity
    enumerize :nature, :in => Nomenclatures["entity_natures-legal_entity"].list, :default => Nomenclatures["entity_natures-legal_entity"].list.first, :predicates => {:prefix => true}

end
