# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
# == Table: tax_declarations
#
#  accounted_at             :datetime
#  acquisition_amount       :decimal(19, 4)
#  address                  :string(255)
#  amount                   :decimal(19, 4)
#  assimilated_taxes_amount :decimal(19, 4)
#  balance_amount           :decimal(19, 4)
#  collected_amount         :decimal(19, 4)
#  created_at               :datetime         not null
#  creator_id               :integer
#  declared_on              :date
#  deferred_payment         :boolean
#  financial_year_id        :integer
#  id                       :integer          not null, primary key
#  journal_entry_id         :integer
#  lock_version             :integer          default(0), not null
#  nature                   :string(255)      default("normal"), not null
#  paid_amount              :decimal(19, 4)
#  paid_on                  :date
#  started_on               :date
#  stopped_on               :date
#  updated_at               :datetime         not null
#  updater_id               :integer
#


