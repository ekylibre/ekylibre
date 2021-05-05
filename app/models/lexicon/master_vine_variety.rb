# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: master_vine_varieties
#
#  category_name    :string           not null
#  color            :string
#  customs_code     :string
#  fr_validated     :string
#  id               :string           not null, primary key
#  specie_long_name :string
#  specie_name      :string           not null
#  utility          :string
#
class MasterVineVariety < LexiconRecord
  self.primary_key = 'id'
  include Lexiconable
  scope :vine_varieties, -> { where(category_name: %w[Cépage Hybride]) }
  scope :rootstocks, -> { where(category_name: 'Porte-greffe') }

  alias_attribute :vine_variety_name, :specie_name
  alias_attribute :rootstock_name, :specie_name
end
