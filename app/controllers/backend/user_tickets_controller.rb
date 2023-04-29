# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
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
  class UserTicketsController < Backend::BaseController
    manage_restfully

    unroll

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    def self.list_conditions
      code = search_conditions(user_tickets: %i[name description agent_email]) + " ||= []\n"
      code.c
    end

    list(conditions: list_conditions) do |t|
      t.column :used_on, datatype: :date
      t.column :name
      t.column :ticket_quantity, datatype: :integer
      t.column :agent_email
      t.column :user_email, hidden: true
      t.column :description, datatype: :text, hidden: true
    end
  end
end
