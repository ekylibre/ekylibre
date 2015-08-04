# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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

class VersionChange < Struct.new(:version, :attribute, :old_value, :new_value)
  def human_attribute_name
    version.item.class.human_attribute_name(attribute)
  end

  def human_old_value
    human_value(old_value)
  end

  def human_new_value
    human_value(new_value)
  end

  private

  def model
    version.item.class
  end

  def human_value(value)
    attr = model.enumerized_attributes[attribute]
    (attr ? attr.human_value_name(value) : value.respond_to?(:l) ? value.l : value).to_s
  end
end
