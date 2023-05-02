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
# == Table: technical_sequences
#
#  family                    :string
#  production_reference_name :string           not null
#  production_system         :string
#  reference_name            :string           not null, primary key
#  translation_id            :string           not null
#
class TechnicalSequence < LexiconRecord
  include Lexiconable
  include ScopeIntrospection
  belongs_to :translation, class_name: 'MasterTranslation'
  has_many :tactics, class_name: 'ActivityTactic', foreign_key: :technical_workflow_sequence_id
  has_many :sequences,  class_name: 'TechnicalWorkflowSequence', foreign_key: :technical_sequence_id

  scope(:of_families, proc { |*families|
    where(family: families.flatten.collect { |f| Onoma::ActivityFamily.all(f.to_sym) }.flatten.uniq.map(&:to_s))
  })

  scope(:of_family, proc { |family|
    where(family: Onoma::ActivityFamily.all(family))
  })

  scope :of_production, lambda { |reference_name|
    where(production_reference_name: reference_name)
  }

  scope :for_activity, ->(activity) {
    of_family(activity.family)
    .of_production(activity.reference_name)
    .where(production_system: (activity.production_system_name || 'intensive_farming'))
  }

end
