# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::UsersController < BackendController
  manage_restfully

  unroll

  list(order: "locked, last_name", :line_class => "(RECORD.locked ? 'critic' : '')".c) do |t|
    t.column :full_name, url: true
    t.column :first_name, url: true, hidden: true
    t.column :last_name, url: true, hidden: true
    t.column :role, url: {action: :edit}
    t.column :team, url: true, hidden: true
    t.column :administrator
    t.column :employed, hidden: true
    t.action :locked, :actions => {true => {action: :unlock}, false => {action: :lock}}, method: :post, if: 'RECORD.id != current_user.id'.c
    t.action :edit, controller: :users
    t.action :destroy, if: 'RECORD.id != current_user.id'.c
  end

  # def new
  #   if request.xhr? and params[:mode] == "rights"
  #     role = Role.find(params[:user_role_id]) rescue nil
  #     @rights = role.rights_array if role
  #     render :partial => "rights_form"
  #   else
  #     role = Role.first
  #     @user = User.new(administrator: false, role: role, employed: params[:employed], language: Preference[:language])
  #     @rights = role ? role.rights_array : []
  #   end
  # end

  # def create
  #   @user = User.new permitted_params #(params[:user])
  #   @user.rights_array = (params[:rights]||{}).keys
  #   @rights = @user.rights_array
  #   return if save_and_redirect(@user)
  # end

  # def edit
  #   return unless @user = find_and_check
  #   @rights = @user.rights_array
  #   t3e @user.attributes
  #   # render_restfully_form
  # end

  # def update
  #   return unless @user = find_and_check
  #   @user.attributes = permitted_params
  #   @user.rights_array = (params[:rights]||{}).keys
  #   @rights = @user.rights_array
  #   return if save_and_redirect(@user, url: {action: :index})
  #   t3e @user.attributes
  # end

  def lock
    return unless @user = find_and_check
    @user.update_attribute(:locked, true)
    redirect_to_current
  end

  def unlock
    return unless @user = find_and_check
    @user.update_attribute(:locked, false)
    redirect_to_current
  end

end
