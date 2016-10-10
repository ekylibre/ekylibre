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
# == Table: entities
#
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string
#  authorized_payments_count :integer
#  born_at                   :datetime
#  client                    :boolean          default(FALSE), not null
#  client_account_id         :integer
#  codes                     :jsonb
#  country                   :string
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  custom_fields             :jsonb
#  dead_at                   :datetime
#  deliveries_conditions     :string
#  description               :text
#  employee                  :boolean          default(FALSE), not null
#  employee_account_id       :integer
#  first_met_at              :datetime
#  first_name                :string
#  full_name                 :string           not null
#  id                        :integer          not null, primary key
#  language                  :string           not null
#  last_name                 :string           not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          default(FALSE), not null
#  meeting_origin            :string
#  nature                    :string           not null
#  number                    :string
#  of_company                :boolean          default(FALSE), not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  proposer_id               :integer
#  prospect                  :boolean          default(FALSE), not null
#  reminder_submissive       :boolean          default(FALSE), not null
#  responsible_id            :integer
#  siret_number              :string
#  supplier                  :boolean          default(FALSE), not null
#  supplier_account_id       :integer
#  title                     :string
#  transporter               :boolean          default(FALSE), not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  vat_number                :string
#  vat_subjected             :boolean          default(TRUE), not null
#

require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  test_model_actions
  test 'nature' do
    entity = Entity.create(nature: :zarb)
    assert entity.errors.include?(:nature), 'Entity must not accept invalid nature'
    entity = Entity.create(nature: :contact)
    assert !entity.errors.include?(:nature), 'Entity must accept contact nature'
    entity = Entity.create(nature: :organization)
    assert !entity.errors.include?(:nature), 'Entity must accept organization nature'
  end
end
