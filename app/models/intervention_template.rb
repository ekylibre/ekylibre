# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: intervention_templates
#
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  description :string
#  id          :integer          not null, primary key
#  name        :string
#  updated_at  :datetime         not null
#
class InterventionTemplate < ActiveRecord::Base
  # Validation
  validates :name, :procedure_name, :workflow, presence: true

  # Relation
  has_many :product_parameters, class_name: 'InterventionTemplate::ProductParameter', foreign_key: :intervention_template_id, dependent: :destroy
  has_many :association_activities, class_name: 'InterventionTemplateActivity', foreign_key: :intervention_template_id
  has_many :activities, through: :association_activities

  # Nested attributes
  accepts_nested_attributes_for :product_parameters, allow_destroy: true
  accepts_nested_attributes_for :association_activities

  # The Procedo::Procedure behind intervention
  def procedure
    Procedo.find(procedure_name)
  end
end
