# -*- coding: utf-8 -*-
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

class Backend::UsersController < BackendController
  manage_restfully

  unroll :first_name, :last_name

  list(order: "locked, last_name", line_class: "(RECORD.locked ? 'critic' : '')".c) do |t|
    t.column :full_name, url: true
    t.column :first_name, url: true, hidden: true
    t.column :last_name, url: true, hidden: true
    t.column :role, url: true
    t.column :team, url: true, hidden: true
    t.column :administrator
    t.column :employed, hidden: true
    t.action :locked, actions: {true => {action: :unlock}, false => {action: :lock}}, method: :post, if: 'RECORD.id != current_user.id'.c
    t.action :edit, controller: :users
    t.action :destroy, if: 'RECORD.id != current_user.id'.c
  end

  def lock
    return unless @user = find_and_check
    @user.lock
    redirect_to_back
  end

  def unlock
    return unless @user = find_and_check
    @user.unlock
    redirect_to_back
  end

end
