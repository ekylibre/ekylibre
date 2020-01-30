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
# == Table: intervention_costings
#
#  created_at      :datetime
#  creator_id      :integer
#  doers_cost      :decimal(, )
#  id              :integer          not null, primary key
#  inputs_cost     :decimal(, )
#  lock_version    :integer          default(0), not null
#  receptions_cost :decimal(, )
#  tools_cost      :decimal(, )
#  updated_at      :datetime
#  updater_id      :integer
#
class InterventionCosting < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :doers_cost, :inputs_cost, :receptions_cost, :tools_cost, numericality: true, allow_blank: true
  # ]VALIDATORS]
  has_one :intervention, inverse_of: :costing, foreign_key: :costing_id
end
