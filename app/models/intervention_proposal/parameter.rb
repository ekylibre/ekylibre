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
# == Table: intervention_proposal_parameters
#
#  created_at                                 :datetime         not null
#  id                                         :integer(4)       not null, primary key
#  intervention_proposal_id                   :integer(4)
#  intervention_template_product_parameter_id :integer(4)
#  product_id                                 :integer(4)
#  product_nature_variant_id                  :integer(4)
#  product_type                               :string
#  quantity                                   :decimal(, )
#  unit                                       :string
#  updated_at                                 :datetime         not null
#

class InterventionProposal < ApplicationRecord
  class Parameter < ApplicationRecord
    belongs_to :intervention_proposal, class_name: 'InterventionProposal'
    belongs_to :variant, class_name: 'ProductNatureVariant', foreign_key: :product_nature_variant_id
    belongs_to :product, class_name: 'Product'
    belongs_to :intervention_template_product_parameter, class_name: 'InterventionTemplate::ProductParameter'

    scope :of_product_type, ->(product_type) { where(product_type: product_type) }
  end
end
