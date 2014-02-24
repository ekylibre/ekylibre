# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::RolesController < BackendController
  manage_restfully only: [:index, :destroy]
  unroll

  list(order: :name, :children => :users) do |t|
    t.column :name, :children => :label
    t.column :diff_more, class: 'rights more'
    t.column :diff_less, class: 'rights less'
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  def new
    @role = Role.new
    @rights = User.rights_list
    # render_restfully_form
  end

  def create
    @role = Role.new(permitted_params[:role])
    @role.rights_array = (params[:rights]||{}).keys
    @rights = @role.rights_array
    return if save_and_redirect(@role)
    # render_restfully_form
  end

  def edit
    return unless @role = find_and_check
    @rights = @role.rights_array
    t3e @role.attributes
    # render_restfully_form
  end

  def update
    return unless @role = find_and_check
    @role.attributes = permitted_params[:role]
    @role.rights_array = (params[:rights]||{}).keys
    @rights = @role.rights_array
    return if save_and_redirect(@role)
    t3e @role.attributes
    # render_restfully_form
  end

end
