# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: naming_format_fields
#
#  field_name       :string           not null
#  id               :integer          not null, primary key
#  naming_format_id :integer
#  position         :integer
#  type             :string           not null
#
class NamingFormatField < Ekylibre::Record::Base
  belongs_to :naming_format

  before_create do
    last_field = naming_format.fields.last
    self.position = 0 unless naming_format.fields.any?
    self.position = last_field.position + 1 if naming_format.fields.any?
  end
end
