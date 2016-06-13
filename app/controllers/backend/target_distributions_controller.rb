# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
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
  class TargetDistributionsController < Backend::BaseController
    manage_restfully except: [:show]

    list order: { started_at: :desc } do |t|
      t.action :edit
      t.action :destroy
      t.column :target, url: true
      t.column :activity, url: true
      t.column :activity_production, url: true
      t.column :started_at
      t.column :stopped_at
    end
  end
end
