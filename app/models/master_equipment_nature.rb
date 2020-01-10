# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: master_equipment_natures
#
#  id                          :integer          not null, primary key
#  main_frozen_indicator_name  :string
#  main_frozen_indicator_unit  :string
#  name                        :jsonb
#  nature                      :string           not null
#  other_frozen_indicator_name :string
#
class MasterEquipmentNature < ActiveRecord::Base
  include Lexiconable
  has_many :categories, class_name: 'MasterEquipmentCost',
                        foreign_key: :equipment_nature_id,
                        dependent: :restrict_with_exception
  has_many :flows, class_name: 'MasterEquipmentFlow',
                   foreign_key: :equipment_nature_id,
                   dependent: :restrict_with_exception
end
