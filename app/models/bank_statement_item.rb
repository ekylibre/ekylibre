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
# == Table: bank_statement_items
#
#  bank_statement_id :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  credit            :decimal(19, 4)   default(0.0), not null
#  currency          :string           not null
#  debit             :decimal(19, 4)   default(0.0), not null
#  id                :integer          not null, primary key
#  initiated_on      :date
#  letter            :string
#  lock_version      :integer          default(0), not null
#  name              :string           not null
#  transaction_id    :string
#  transfered_on     :date             not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class BankStatementItem < Ekylibre::Record::Base
  refers_to :currency
  belongs_to :bank_statement
  has_one :cash, through: :bank_statement
  has_one :journal, through: :cash
  has_one :account, through: :cash

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_date :initiated_on, :transfered_on, allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }
  validates_numericality_of :credit, :debit, allow_nil: true
  validates_presence_of :bank_statement, :credit, :currency, :debit, :name, :transfered_on
  # ]VALIDATORS]

  validate do
    errors.add(:credit, :unvalid_amounts) if debit != 0 && credit != 0
  end
end
