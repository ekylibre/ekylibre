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
# == Table: contract_natures
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  currency     :string           not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

class ContractNature < Ekylibre::Record::Base
  refers_to :currency
  has_many :contracts, foreign_key: :nature_id, dependent: :restrict_with_exception

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :currency, presence: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :name, uniqueness: true

  before_validation(on: :create) do
    self.currency ||= Preference[:currency]
  end

  protect on: :destroy do
    contracts.any?
  end
end
