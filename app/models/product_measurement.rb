# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2013 Brice Texier, David Joulin
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
# == Table: product_measurements
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  indicator_name  :string(255)      not null
#  lock_version    :integer          default(0), not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string(255)
#  product_id      :integer          not null
#  reporter_id     :integer
#  started_at      :datetime         not null
#  stopped_at      :datetime
#  tool_id         :integer
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductMeasurement < Ekylibre::Record::Base
  include Taskable
  belongs_to :product
  belongs_to :reporter, class_name: "Worker"
  belongs_to :tool, class_name: "Product"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :indicator_name, :originator_type, allow_nil: true, maximum: 255
  validates_presence_of :indicator_name, :product, :started_at
  #]VALIDATORS]

  validate do
    if self.product and self.indicator
      unless self.product.indicators.include?(self.indicator)
        errors.add(:indicator, :invalid)
      end
    end
  end

  def indicator
    Nomen::Indicator[self.indicator_name]
  end

end
