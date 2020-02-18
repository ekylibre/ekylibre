# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: net_services
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  reference_name :string           not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#
class NetService < Ekylibre::Record::Base
  refers_to :reference_name, class_name: 'NetService'
  has_many :identifiers, -> { order(:nature) }
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :reference_name, presence: true
  # ]VALIDATORS]
  validates :reference_name, uniqueness: true

  accepts_nested_attributes_for :identifiers

  delegate :url, to: :reference

  def name
    reference_name.l
  end

  def reference
    Nomen::NetService[reference_name]
  end

  def each_identifier(&_block)
    if reference
      reference.identifiers.each do |identifier|
        yield Nomen::IdentifierNature[identifier]
      end
    end
  end
end
