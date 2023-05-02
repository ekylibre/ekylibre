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
# == Table: technical_workflow_procedures
#
#  bbch_stage            :string
#  frequency             :string
#  name                  :jsonb            not null
#  period                :string
#  position              :integer(4)       not null
#  procedure_reference   :string           not null
#  reference_name        :string           not null, primary key
#  repetition            :integer(4)
#  technical_workflow_id :string           not null
#
class TechnicalWorkflowProcedure < LexiconRecord
  include Lexiconable
  has_many :items, class_name: 'TechnicalWorkflowProcedureItem', foreign_key: :technical_workflow_procedure_id, dependent: :restrict_with_exception
  belongs_to :intervention_model, class_name: 'InterventionModel', foreign_key: :procedure_reference
  with_options inverse_of: :intervention do
    has_many :inputs, -> { where(actor_reference: 'input') }, class_name: 'TechnicalWorkflowProcedureItem', foreign_key: :technical_workflow_procedure_id
    has_many :outputs, -> { where(actor_reference: 'output') }, class_name: 'TechnicalWorkflowProcedureItem', foreign_key: :technical_workflow_procedure_id
  end
end
