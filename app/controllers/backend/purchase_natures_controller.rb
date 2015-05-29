# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012 Brice Texier
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

class Backend::PurchaseNaturesController < Backend::BaseController
  manage_restfully currency: "Preference[:currency]".c

  unroll

  list do |t|
    t.action :edit
    t.action :destroy
    t.column :name, url: true
    t.column :active
    t.column :currency
    t.column :with_accounting
    t.column :journal, url: true
  end

end
