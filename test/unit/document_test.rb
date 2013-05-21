# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
#  archived_at       :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  file_content_type :string(255)
#  file_file_name    :string(255)
#  file_file_size    :integer
#  file_fingerprint  :string(255)
#  file_updated_at   :datetime
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  nature            :string(63)       not null
#  origin_id         :integer
#  origin_type       :string(255)
#  template_id       :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#
require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
end
