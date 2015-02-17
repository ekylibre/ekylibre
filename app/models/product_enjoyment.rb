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
# == Table: product_enjoyments
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  enjoyer_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  nature          :string           not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string
#  product_id      :integer          not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductEnjoyment < Ekylibre::Record::Base
  include Taskable, TimeLineable
  belongs_to :enjoyer, class_name: "Entity"
  belongs_to :product
  # enumerize :nature, in: [:unknown, :own, :other], default: :unknown, predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :nature, :product
  #]VALIDATORS]

  before_validation do
    self.nature = (self.enjoyer.blank? ? :unknown : (self.enjoyer == Entity.of_company) ? :own : :other)
  end

  private

  def siblings
    self.product.enjoyments
  end

end
