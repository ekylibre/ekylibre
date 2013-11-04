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
# == Table: operation_tasks
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nature       :string(255)      not null
#  operation_id :integer          not null
#  parent_id    :integer
#  prorated     :boolean          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class OperationTask < Ekylibre::Record::Base
  belongs_to :operation, inverse_of: :tasks
  belongs_to :parent, class_name: "OperationTask"
  has_many :casts, class_name: "OperationTaskCast", inverse_of: :task
  enumerize :nature, in: Procedo::Action::TYPES.keys, predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :allow_nil => true, :maximum => 255
  validates_inclusion_of :prorated, :in => [true, false]
  validates_presence_of :nature, :operation
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values
end
