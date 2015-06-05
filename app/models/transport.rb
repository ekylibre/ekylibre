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
# == Table: transports
#
#  annotation              :text
#  created_at              :datetime         not null
#  creator_id              :integer
#  departed_at             :datetime
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  net_mass                :decimal(19, 4)
#  number                  :string
#  reference_number        :string
#  responsible_id          :integer
#  transporter_id          :integer          not null
#  transporter_purchase_id :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#


class Transport < Ekylibre::Record::Base
  acts_as_numbered
  belongs_to :responsible, class_name: "Contact"
  belongs_to :transporter, class_name: "Entity"
  belongs_to :transporter_purchase, class_name: "Purchase"
  has_many :deliveries, class_name: "OutgoingDelivery", dependent: :nullify

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :departed_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :net_mass, allow_nil: true
  validates_presence_of :transporter
  #]VALIDATORS]

  protect(on: :destroy) do
    self.deliveries.any?
  end

  def refresh
    self.save
  end

end
