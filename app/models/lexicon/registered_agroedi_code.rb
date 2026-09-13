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
# == Table: registered_agroedi_codes
#
#  ekylibre_scope  :string
#  ekylibre_value  :string
#  reference_code  :string
#  reference_id    :integer(4)       not null
#  reference_label :string
#  repository_id   :integer(4)       not null
#
class RegisteredAgroediCode < LexiconRecord
  include Lexiconable

  # La table n'a ni clé primaire ni index unique : `first` y rendait une ligne
  # arbitraire, au gré du plan choisi par PostgreSQL. `reference_id` est l'une
  # des deux colonnes non nulles et suffit à rendre cet ordre déterministe.
  self.implicit_order_column = :reference_id

  scope :of_reference_code, ->(code) { where(reference_code: code.to_s) }
  scope :of_ekylibre_codes, lambda { |context, value|
    where(ekylibre_scope: context.to_s, reference_code: value.to_s)
  }
end
