# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: product_grading_checks
#
#  activity_grading_check_id :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  id                        :integer          not null, primary key
#  items_count               :integer
#  lock_version              :integer          default(0), not null
#  maximal_size_value        :decimal(19, 4)
#  minimal_size_value        :decimal(19, 4)
#  net_mass_value            :decimal(19, 4)
#  product_grading_id        :integer          not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

class ProductGradingCheck < Ekylibre::Record::Base
  belongs_to :activity_grading_check
  belongs_to :product_grading, inverse_of: :checks
  has_one :activity, through: :activity_grading_check
  has_one :product, through: :product_grading
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :maximal_size_value, :minimal_size_value, :net_mass_value, allow_nil: true
  validates_presence_of :activity_grading_check, :product_grading
  # ]VALIDATORS]

  delegate :nature, :name, to: :activity_grading_check
  delegate :human_grading_net_mass_unit_name, :human_grading_calibre_unit_name, :human_grading_sizes_unit_name, to: :activity
  delegate :measure_grading_net_mass, :measure_grading_items_count, :measure_grading_sizes, to: :activity

  scope :of_nature, lambda { |nature|
    where(activity_grading_check_id: ActivityGradingCheck.select(:id).where(nature: nature))
  }
  
  scope :of_products, lambda { |*products|
    where(product_grading_id: ProductGrading.of_products(products).pluck(:id))
  }
end
