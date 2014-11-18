# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
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
#
# == Table: product_linkages
#
#  carried_id      :integer
#  carrier_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  nature          :string(255)      not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string(255)
#  point           :string(255)      not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductLinkage < Ekylibre::Record::Base
  include Taskable, TimeLineable
  belongs_to :carrier, class_name: 'Product'
  belongs_to :carried, class_name: 'Product'
  enumerize :nature, in: [:available, :unavailable, :occupied], default: :available, predicates: true
  enumerize :point, in: [:rear, :front]
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_length_of :nature, :originator_type, :point, allow_nil: true, maximum: 255
  validates_presence_of :carrier, :nature, :point
  #]VALIDATORS]
  validates_presence_of :carried, if: :occupied?

  scope :with, lambda { |point| where(point: point) }

  after_save do
    # # If carried is already carried, detach it!
    # if self.occupied? and self.carried
    #   self.carried.carrier_linkages.at(self.started_at).find_each do |linkage|
    #     self.product_linkages.create!(carrier_id: linkage.carrier_id, operation: self.operation, point: linkage.point, started_at: self.started_at, nature: :available)
    #   end
    # end
  end

  private

  # Returns all siblings in the chronological line
  def siblings
    self.carrier.linkages.with(self.point)
  end

end
