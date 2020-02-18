# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: documents
#
#  created_at         :datetime         not null
#  creator_id         :integer
#  custom_fields      :jsonb
#  file_content_text  :text
#  file_content_type  :string
#  file_file_name     :string
#  file_file_size     :integer
#  file_fingerprint   :string
#  file_pages_count   :integer
#  file_updated_at    :datetime
#  id                 :integer          not null, primary key
#  key                :string           not null
#  lock_version       :integer          default(0), not null
#  mandatory          :boolean          default(FALSE)
#  name               :string           not null
#  nature             :string
#  number             :string           not null
#  sha256_fingerprint :string
#  signature          :text
#  template_id        :integer
#  updated_at         :datetime         not null
#  updater_id         :integer
#  uploaded           :boolean          default(FALSE), not null
#
require 'test_helper'

class DocumentTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
