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
# == Table: net_services
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  reference_name :string(255)      not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#
class NetService < Ekylibre::Record::Base
  enumerize :reference_name, in: Nomen::NetServices.all
  has_many :identifiers
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :reference_name, allow_nil: true, maximum: 255
  validates_presence_of :reference_name
  #]VALIDATORS]
  validates_uniqueness_of :reference_name

  def name
    self.reference_name.text
  end

  def reference
    Nomen::NetServices[self.reference_name]
  end

end
