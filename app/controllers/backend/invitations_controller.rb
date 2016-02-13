# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class InvitationsController < Backend::BaseController

    list(model: :users,
         conditions: ["#{User.table_name}.invitation_created_at IS NOT NULL"],
         order: 'users.last_name') do |t|
      t.action :destroy, if: 'RECORD.invitation_accepted_at.nil?'.c
      t.column :first_name
      t.column :last_name
      t.column :email
      t.column :role, url: true
      t.column :invitation_status
    end
  end
end
