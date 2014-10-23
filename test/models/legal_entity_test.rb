# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: entities
#
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string(30)
#  authorized_payments_count :integer
#  born_at                   :datetime
#  client                    :boolean          not null
#  client_account_id         :integer
#  country                   :string(2)
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string(255)      not null
#  dead_at                   :datetime
#  deliveries_conditions     :string(60)
#  description               :text
#  first_met_at              :datetime
#  first_name                :string(255)
#  full_name                 :string(255)      not null
#  id                        :integer          not null, primary key
#  language                  :string(3)        not null
#  last_name                 :string(255)      not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          not null
#  meeting_origin            :string(255)
#  nature                    :string(255)      not null
#  number                    :string(60)
#  of_company                :boolean          not null
#  picture_content_type      :string(255)
#  picture_file_name         :string(255)
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  proposer_id               :integer
#  prospect                  :boolean          not null
#  reminder_submissive       :boolean          not null
#  responsible_id            :integer
#  siren                     :string(9)
#  supplier                  :boolean          not null
#  supplier_account_id       :integer
#  transporter               :boolean          not null
#  type                      :string(255)
#  updated_at                :datetime         not null
#  updater_id                :integer
#  vat_number                :string(20)
#  vat_subjected             :boolean          default(TRUE), not null
#
require 'test_helper'

class LegalEntityTest < ActiveSupport::TestCase

  # Replace this with your real tests.'
  test "the truth" do
    assert true
  end

end
