# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  active                    :boolean          default(FALSE), not null
#  activity_code             :string(255)
#  authorized_payments_count :integer
#  born_at                   :datetime
#  client                    :boolean          not null
#  client_account_id         :integer
#  country                   :string(255)
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string(255)      not null
#  dead_at                   :datetime
#  deliveries_conditions     :string(255)
#  description               :text
#  first_met_at              :datetime
#  first_name                :string(255)
#  full_name                 :string(255)      not null
#  id                        :integer          not null, primary key
#  language                  :string(255)      not null
#  last_name                 :string(255)      not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          not null
#  meeting_origin            :string(255)
#  nature                    :string(255)      not null
#  number                    :string(255)
#  of_company                :boolean          not null
#  picture_content_type      :string(255)
#  picture_file_name         :string(255)
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  proposer_id               :integer
#  prospect                  :boolean          not null
#  reminder_submissive       :boolean          not null
#  responsible_id            :integer
#  siren                     :string(255)
#  supplier                  :boolean          not null
#  supplier_account_id       :integer
#  transporter               :boolean          not null
#  type                      :string(255)
#  updated_at                :datetime         not null
#  updater_id                :integer
#  vat_number                :string(255)
#  vat_subjected             :boolean          default(FALSE), not null
#
class Person < Entity
  enumerize :nature, in: Nomen::EntityNatures.all(:person), default: Nomen::EntityNatures.default(:person), predicates: {prefix: true}

  has_one :worker
  has_one :user
  has_one :team, through: :user
  scope :users, -> { where(id: User.all) }

  scope :employees, -> { joins(:direct_links).merge(EntityLink.of_nature(:work)) }

  scope :employees_of, lambda { |boss|
    joins(:direct_links).merge(EntityLink.of_nature(:work).where(entity_2_id: (boss.respond_to?(:id) ? boss.id : boss)))
  }

end
