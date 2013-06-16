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
# == Table: events
#
#  created_at        :datetime         not null
#  creator_id        :integer
#  description       :text
#  duration          :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  meeting_nature_id :integer
#  name              :text
#  nomen             :string(255)
#  parent_id         :integer
#  place             :string(255)
#  procedure_id      :integer
#  started_at        :datetime         not null
#  stopped_at        :datetime
#  type              :string(255)      not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#
require 'test_helper'

class ProcedureTest < ActiveSupport::TestCase

  test "presence of fixtures" do
    # assert_equal 2, Procedure.count
  end

end
