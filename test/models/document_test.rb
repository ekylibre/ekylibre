# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: documents
#
#  archives_count :integer          default(0), not null
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  key            :string(255)      not null
#  lock_version   :integer          default(0), not null
#  name           :string(255)      not null
#  nature         :string(120)      not null
#  number         :string(60)       not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#
require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
end
