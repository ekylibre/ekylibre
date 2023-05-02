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
# == Table: intervention_model_items
#
#  article_reference        :string
#  indicator_name           :string
#  indicator_unit           :string
#  indicator_value          :decimal(19, 4)
#  intervention_model_id    :string
#  procedure_item_reference :string           not null
#  reference_name           :string           not null, primary key
#

class InterventionModelItem < LexiconRecord
  include Lexiconable
  belongs_to :intervention_model, class_name: 'InterventionModel', foreign_key: :intervention_model_id

  delegate :procedure, to: :intervention_model
  delegate :type, to: :parameter, prefix: true, allow_nil: true

  def parameter
    return nil if procedure.nil? || procedure_item_reference.nil?

    procedure.find(procedure_item_reference)
  end

  def product_parameter_type
    ('intervention_template/' + parameter_type.to_s).camelize
  end
end
