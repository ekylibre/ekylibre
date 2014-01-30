# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: product_junctions
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string(255)
#  started_at      :datetime
#  stopped_at      :datetime
#  tool_id         :integer
#  type            :string(255)
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductCreation < ProductBirth
  has_way :producer

  after_save do
    if self.producer
      # Nothing to do
    else
      for indicator_name in self.product.whole_indicators_list
        if self.send(indicator_name)
          product.is_measured!(indicator_name, self.send(indicator_name), at: self.stopped_at, originator: self)
        end
      end
    end
  end

end
