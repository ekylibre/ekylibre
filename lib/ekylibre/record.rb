# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#


module Ekylibre
  module Record
    autoload :Base, 'ekylibre/record/base'
  end
end

require_relative('record/bookkeep')
require_relative('record/autosave')
require_relative('record/selects_among_all')
require_relative('record/has_shape')
require_relative('record/sums')
require_relative('record/dependents')
# require_relative('record/transfer')
require_relative('record/acts/numbered')
require_relative('record/acts/reconcilable')
require_relative('record/acts/affairable')
require_relative('record/acts/protected')
