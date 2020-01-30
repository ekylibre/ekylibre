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
# == Table: product_enjoyments
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  enjoyer_id      :integer
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
class ProductEnjoyment < Ekylibre::Record::Base
  include TimeLineable
  include Taskable
  belongs_to :enjoyer, class_name: 'Entity'
  belongs_to :product
  enumerize :nature, in: %i[unknown own other], default: :unknown, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :nature, :product, presence: true
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(product_enjoyment) { product_enjoyment.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :enjoyer, presence: { if: :other? }

  before_validation do
    self.nature ||= (enjoyer.blank? ? :unknown : enjoyer == Entity.of_company ? :own : :other)
  end

  private

  def siblings
    product&.enjoyments || ProductEnjoyment.none
  end
end
