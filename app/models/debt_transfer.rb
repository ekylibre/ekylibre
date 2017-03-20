# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: debt_transfers
#
#  accounted_at                             :datetime
#  amount                                   :decimal(, )
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  id                                       :integer          not null, primary key
#  lock_version                             :integer          default(0), not null
#  purchase_affair_id                       :integer          not null
#  purchase_regularization_journal_entry_id :integer          not null
#  sale_affair_id                           :integer          not null
#  sale_regularization_journal_entry_id     :integer          not null
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
class DebtTransfer < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, numericality: true, allow_blank: true
  validates :currency, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
end
