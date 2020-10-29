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
# == Table: dashboards
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  owner_id     :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Dashboard < Ekylibre::Record::Base
  belongs_to :owner, class_name: 'User'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :owner, presence: true
  # ]VALIDATORS]

  before_validation on: :create do
    self.owner ||= Version.current_user
  end
end
