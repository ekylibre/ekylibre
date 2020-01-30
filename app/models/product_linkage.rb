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
# == Table: product_linkages
#
#  carried_id      :integer
#  carrier_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  intervention_id :integer
#  lock_version    :integer          default(0), not null
#  nature          :string           not null
#  originator_id   :integer
#  originator_type :string
#  point           :string           not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductLinkage < Ekylibre::Record::Base
  include TimeLineable
  include Taskable
  belongs_to :carrier, class_name: 'Product'
  belongs_to :carried, class_name: 'Product'
  enumerize :nature, in: %i[available unavailable occupied], default: :available, predicates: true
  enumerize :point, in: %i[rear front]
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :carrier, :nature, :point, presence: true
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(product_linkage) { product_linkage.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :carried, presence: { if: :occupied? }

  scope :with, ->(point) { where(point: point) }

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
    carrier&.linkages&.with(point) || ProductLinkage.none
  end
end
