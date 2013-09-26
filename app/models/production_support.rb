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
# == Table: production_supports
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  exclusive     :boolean          not null
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  production_id :integer          not null
#  started_at    :datetime
#  stopped_at    :datetime
#  storage_id    :integer          not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#
class ProductionSupport < Ekylibre::Record::Base
  belongs_to :storage, :class_name => "Product", :inverse_of => :supports
  belongs_to :production, :inverse_of => :supports
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :exclusive, :in => [true, false]
  validates_presence_of :production, :storage
  #]VALIDATORS]
  validates_uniqueness_of :storage_id, scope: :production_id

  delegate :shape_area, to: :storage, prefix: true
end


