# = Informations
#
# == License
#
# Ekylibre - Simple ERP
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
    # VERSION = '0.0.1'
  end
end

dir = File.join(File.dirname(__FILE__), 'record')
require File.join(dir, 'base')
require File.join(dir, 'bookkeep')
require File.join(dir, 'autosave')
require File.join(dir, 'default')
require File.join(dir, 'sums')
require File.join(dir, 'preference')
require File.join(dir, 'dependents')
# require File.join(dir, 'transfer')
require File.join(dir, 'acts', 'numbered')
require File.join(dir, 'acts', 'reconcilable')
require File.join(dir, 'acts', 'stockable')
require File.join(dir, 'acts', 'affairable')
require File.join(dir, 'acts', 'protected')
# require File.join(dir, 'company_record')
