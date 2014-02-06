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
class ProductDivision < ProductBirth
  has_way :producer

  after_save do
    # Duplicate individual indicator data
    product.copy_indicator_data_of!(producer, at: self.stopped_at, taken_at: self.started_at, originator: self)

    # Impact on following readings
    for indicator_name in producer.whole_indicators_list
      producer.is_measured!(indicator_name, producer.get(indicator_name, at: self.stopped_at), at: self.stopped_at)
      if product_datum_value = self.product_way.send(indicator_name)
        producer.substract_to_indicator_data(indicator_name, product_datum_value, after: self.stopped_at)
      else
        raise StandardError, "No given value for #{indicator_name}."
      end
    end

    # # Add whole indicator data
    # for indicator_name in producer.whole_indicators_list
    #   producer_datum_value = producer.send(indicator_name, at: self.started_at)
    #   product_datum_value = self.product_way.send(indicator_name)
    #   if producer_datum_value and product_datum_value
    #     product.is_measured!(indicator_name,  product_datum_value, at: self.stopped_at, originator: self)
    #     producer.is_measured!(indicator_name, producer_datum_value - product_datum_value, at: self.stopped_at, originator: self)
    #   else
    #     if producer_datum_value.nil? and product_datum_value.nil?
    #       puts "Cannot divide empty #{indicator_name.to_s.pluralize} between producer ##{producer.id} and produced ##{product.id}."
    #     else
    #       raise "Need to divide #{indicator_name} but no way to do it properly\n" +
    #         {producer: producer_datum_value, produced: product_datum_value}.collect{|k,v| "#{k}: #{v.inspect}"}.join("\n")
    #     end
    #   end
    # end
  end

end
