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
# == Table: product_localizations
#
#  container_id    :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  intervention_id :integer
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

class ProductLocalization < Ekylibre::Record::Base
  include TimeLineable
  include Taskable
  belongs_to :container, class_name: 'Product'
  belongs_to :product
  enumerize :nature, in: %i[transfer interior exterior], predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :nature, :product, presence: true
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(product_localization) { product_localization.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :nature, inclusion: { in: nature.values }
  validates :container, presence: { if: :interior? }

  scope :of_product_varieties, lambda { |*varieties|
    joins(:product).merge(Product.of_variety(*varieties))
  }

  before_validation do
    if container
      self.nature ||= (container.owner.nil? || container.owner == Entity.of_company ? :interior : :exterior)
    else
      self.nature = :exterior unless transfer?
    end
  end

  before_save do
    self.container = nil unless interior?
  end

  after_save do
    # # Detach from carrier if exists but only if it has linkage points ?
    # self.product.carrier_linkages.at(self.started_at).find_each do |linkage|
    #   self.product_linkages.create!(carrier_id: linkage.carrier_id, point: linkage.point, started_at: self.started_at, nature: :available)
    # end
    # Move carried products
    product.linkages.at(started_at).find_each do |linkage|
      if linkage.occupied? && carried = linkage.carried
        localization = carried.localizations.at(started_at).first
        if localization.nil? || (localization.nature != nature || localization.container_id != container_id)
          product_localizations.create!(product: linkage.carried, operation: operation, nature: nature, container: container, started_at: started_at)
        end
      end
    end
  end

  # protect do
  #   return intervention.present? unless destroyed_by_association
  #   return false
  # end

  private

  # Returns all siblings in the chronological line
  def siblings
    (product ? product.localizations : self.class.none)
  end
end
