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
# == Table: transports
#
#  amount           :decimal(19, 4)   not null
#  created_at       :datetime         not null
#  created_on       :date
#  creator_id       :integer
#  description      :text
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  net_mass         :decimal(19, 4)
#  number           :string(255)
#  pretax_amount    :decimal(19, 4)   not null
#  purchase_id      :integer
#  reference_number :string(255)
#  responsible_id   :integer
#  transport_on     :date
#  transporter_id   :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Transport < Ekylibre::Record::Base
  acts_as_numbered
  belongs_to :responsible, class_name: "User"
  belongs_to :transporter, class_name: "Entity"
  has_many :deliveries, dependent: :nullify, class_name: "OutgoingDelivery"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :net_mass, :pretax_amount, allow_nil: true
  validates_length_of :number, :reference_number, allow_nil: true, maximum: 255
  validates_presence_of :amount, :pretax_amount, :transporter
  #]VALIDATORS]

  before_validation(on: :create) do
    self.created_on ||= Date.today
    return true
  end

  protect(on: :destroy) do
    return true
  end

  def refresh
    self.save
  end

end
