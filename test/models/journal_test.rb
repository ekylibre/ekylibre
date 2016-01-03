# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: journals
#
#  closed_on        :date             not null
#  code             :string           not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  nature           :string           not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  used_for_affairs :boolean          default(FALSE), not null
#  used_for_gaps    :boolean          default(FALSE), not null
#

require 'test_helper'

class JournalTest < ActiveSupport::TestCase
  test 'presence of nature scopes' do
    for nature in Journal.nature.values
      scope_name = nature.to_s.pluralize.to_sym
      assert Journal.respond_to?(scope_name), "Journal must have a scope #{scope_name}"
      # TODO: Check that scope works
    end
  end
end
