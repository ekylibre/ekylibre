# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: product_localizations
#
#  arrival_cause     :string(255)
#  container_id      :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  departure_cause   :string(255)
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  nature            :string(255)      not null
#  operation_task_id :integer
#  product_id        :integer          not null
#  started_at        :datetime
#  stopped_at        :datetime
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class ProductLocalization < Ekylibre::Record::Base
  belongs_to :container, class_name: "Product"
  belongs_to :operation_task
  belongs_to :product
  enumerize :nature, in: [:transfer, :interior, :exterior], default: :interior, predicates: true
  enumerize :arrival_cause,   in: [:birth, :housing, :other, :purchase], default: :birth, predicates: {prefix: true}
  enumerize :departure_cause, in: [:death, :consumption, :other, :sale], default: :sale,  predicates: {prefix: true}
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :arrival_cause, :departure_cause, :nature, allow_nil: true, maximum: 255
  validates_presence_of :nature, :product
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values
  validates_presence_of :container, if: :interior?

end
