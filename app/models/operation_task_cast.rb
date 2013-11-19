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
# == Table: operation_task_casts
#
#  actor_id     :integer          not null
#  actor_type   :string(255)      not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  task_id      :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#
class OperationTaskCast < Ekylibre::Record::Base
  belongs_to :actor, polymorphic: true
  belongs_to :task, class_name: "OperationTask", inverse_of: :casts
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :actor_type, :name, allow_nil: true, maximum: 255
  validates_presence_of :actor, :actor_type, :name, :task
  #]VALIDATORS]
end
