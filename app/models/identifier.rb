# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
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
# == Table: identifiers
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  nature         :string(255)      not null
#  net_service_id :integer
#  updated_at     :datetime         not null
#  updater_id     :integer
#  value          :string(255)      not null
#
class Identifier < Ekylibre::Record::Base
  enumerize :nature, in: Nomen::IdentifierNatures.all
  belongs_to :net_service
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :value, allow_nil: true, maximum: 255
  validates_presence_of :nature, :value
  #]VALIDATORS]

  validate do
    if self.net_service and self.net_service.reference
      errors.add(:nature, :invalid) unless self.net_service.reference.identifiers.include?(self.nature.to_sym)
    end
  end

end
