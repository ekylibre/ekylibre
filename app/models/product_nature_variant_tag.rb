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
# == Table: product_nature_variant_tags
#
#  created_at                   :datetime         not null
#  creator_id                   :integer(4)
#  document_id                  :integer(4)
#  description                  :text
#  entity_id                    :integer(4)       not null
#  id                           :integer(4)       not null, primary key
#  variant_id                   :integer(4)       not null
#  value                        :string           not null
#

class ProductNatureVariantTag < ApplicationRecord
  belongs_to :variant, class_name: 'ProductNatureVariant', inverse_of: :article_tags
  belongs_to :entity, class_name: 'Entity', inverse_of: :article_tags
  belongs_to :document, class_name: 'Document', inverse_of: :article_tags

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]

end
