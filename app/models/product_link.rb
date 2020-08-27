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
# == Table: product_links
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  intervention_id :integer
#  linked_id       :integer
#  lock_version    :integer          default(0), not null
#  nature          :string           not null
#  originator_id   :integer
#  originator_type :string
#  product_id      :integer          not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class ProductLink < Ekylibre::Record::Base
  include TimeLineable
  include Taskable
  belongs_to :product
  belongs_to :linked, class_name: 'Product'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :nature, presence: true, length: { maximum: 500 }
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(product_link) { product_link.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :product, presence: true
  # ]VALIDATORS]
  validates :linked, presence: true

  scope :with, ->(nature) { where(nature: nature.to_s) }

  # Returns all the siblings
  def siblings
    product&.links&.with(nature) || ProductLink.none
  end
end
