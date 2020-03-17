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
# == Table: regularizations
#
#  affair_id        :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          not null
#  lock_version     :integer          default(0), not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Regularization < Ekylibre::Record::Base
  belongs_to :affair
  belongs_to :journal_entry
  has_one :third, through: :affair
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :currency, presence: true, length: { maximum: 500 }
  validates :affair, :journal_entry, presence: true
  # ]VALIDATORS]
  validates :journal_entry, uniqueness: true
  validates :currency, match: { with: :affair, message: :currency_does_not_match }
  validates :currency, match: { with: :journal_entry, message: :currency_does_not_match }

  delegate :number, to: :journal_entry

  acts_as_affairable class_name: 'SaleAffair'

  before_validation do
    self.currency ||= journal_entry.currency if journal_entry
  end

  after_save do
    journal_entry.update_columns(resource_type: self.class.name, resource_id: id)
  end

  after_destroy do
    journal_entry.update_columns(resource_type: nil, resource_id: nil)
  end
end
