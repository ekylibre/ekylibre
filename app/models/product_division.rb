# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: product_junctions
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string
#  started_at      :datetime
#  stopped_at      :datetime
#  tool_id         :integer
#  type            :string
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductDivision < ProductBirth
  has_way :producer

  after_save do
    # Duplicate individual indicator data
    product.copy_readings_of!(producer, at: stopped_at, taken_at: started_at, originator: self)

    # Impact on following readings
    for indicator_name in producer.whole_indicators_list
      producer.read!(indicator_name, producer.get(indicator_name, at: stopped_at), at: stopped_at)
      if product_reading_value = product_way.send(indicator_name)
        producer.substract_to_readings(indicator_name, product_reading_value, after: stopped_at)
      else
        fail StandardError, "No given value for #{indicator_name}."
      end
    end
  end
end
