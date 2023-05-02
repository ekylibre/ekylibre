# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: daily_charges
#
#  activity_id                                :integer(4)
#  activity_production_id                     :integer(4)
#  animal_population                          :integer(4)
#  area                                       :decimal(, )
#  created_at                                 :datetime         not null
#  id                                         :integer(4)       not null, primary key
#  intervention_template_product_parameter_id :integer(4)
#  product_general_type                       :string
#  product_type                               :string
#  quantity                                   :decimal(, )
#  quantity_unit_id                           :integer(8)
#  reference_date                             :date
#  updated_at                                 :datetime         not null
#

class DailyCharge < ApplicationRecord
  belongs_to :activity_production, class_name: 'ActivityProduction', required: true
  belongs_to :product_parameter, class_name: 'InterventionTemplate::ProductParameter', required: true, foreign_key: :intervention_template_product_parameter_id
  belongs_to :activity
  belongs_to :quantity_unit, class_name: 'Unit'
  has_one :product_nature_variant, through: :product_parameter
  has_one :product_nature, through: :product_parameter
  has_one :intervention_template, through: :product_parameter

  validates :reference_date, :product_type, :quantity, presence: true

  scope :of_type, ->(type) { where(product_general_type: type) }

  scope :of_activity, lambda { |act|
    where(activity: act) if act.present?
  }

  scope :of_activity_production, lambda { |activity_production|
    where(activity_production: activity_production) if activity_production.present?
  }

  scope :between_date, lambda { |from, to|
    where(reference_date: from..to) if from.present? && to.present?
  }

  scope :of_variant, lambda { |variant|
    where(intervention_template_product_parameter_id: InterventionTemplate::ProductParameter.where(product_nature_variant_id: variant.id).pluck(:id))
  }

  scope :of_nature, lambda { |nature|
    where(intervention_template_product_parameter_id: InterventionTemplate::ProductParameter.where(product_nature_id: nature.id).pluck(:id))
  }

  before_save do
    if activity_production.present?
      self.activity_id = self.activity_production.activity.id
    end
  end

  def quantity_with_unit
    if %w[tool doer].include?(product_general_type)
      quantity.round(1).in_hour.localize(precision: 1)
    elsif product_parameter.unit == 'unit'
      "#{quantity}  #{:unit.tl}"
    else
      quantity.round(1).in(Onoma::Unit[product_parameter.unit.gsub(/_per_.*/, '')].symbol).l(precision: 1)
    end
  end

  def available_quantity
    if %w[tool doer].include?(product_general_type)
      product_parameter.product_nature.variants.map(&:current_stock).sum.round(2)
    elsif product_general_type == 'input'
      "#{product_parameter.product_nature_variant.current_stock.round(1).l(precision: 1)} #{product_parameter.product_nature_variant.unit_name}".gsub(',', '.')
    end
  end
end
