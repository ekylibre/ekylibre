# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: units
#
#  base_unit_id   :integer(4)
#  coefficient    :decimal(20, 10)  default(1.0), not null
#  created_at     :datetime
#  creator_id     :integer(4)
#  description    :text
#  dimension      :string           not null
#  id             :integer(4)       not null, primary key
#  lock_version   :integer(4)       default(0), not null
#  name           :string           not null
#  provider       :jsonb
#  reference_name :string
#  symbol         :string
#  type           :string           not null
#  updated_at     :datetime
#  updater_id     :integer(4)
#  work_code      :string
#

class ReferenceUnit < Unit

  validates :base_unit, presence: true, unless: :dimension_reference_unit?

  scope :of_dimensions, ->(*dimensions) { where(dimension: dimensions) }

  after_save do
    self.update_column(:base_unit_id, id) if dimension_reference_unit?
  end

  def dimension_reference_unit?
    BASE_UNIT_PER_DIMENSION.values.include?(reference_name)
  end
end
