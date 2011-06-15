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

class UsersController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>:last_name, :line_class=>"(RECORD.locked ? 'critic' : '')", :per_page=>20) do |t|
    t.column :name, :url=>{:action=>:show}
    t.column :first_name, :url=>{:action=>:show}
    t.column :last_name, :url=>{:action=>:show}
    t.column :name, :through=>:role, :url=>{:action=>:edit}
    # t.column :reduction_percent
    t.column :email
    t.column :admin
    t.column :employed
    t.action :locked, :actions=>{"true"=>{:action=>:unlock},"false"=>{:action=>:lock}}, :method=>:post, :if=>'RECORD.id!=@current_user.id'
    t.action :edit 
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.id!=@current_user.id'
  end

  # Displays details of one user selected with +params[:id]+
  def show
    return unless @user = find_and_check(:user)
    t3e @user.attributes
  end

  def new
    if request.xhr? and params[:mode] == "rights"
      role = @current_company.roles.find(params[:user_role_id]) rescue nil
      @rights = role.rights_array if role
      render :partial=>"rights_form"
    else
      if request.post?
        @user = User.new(params[:user])
        @user.company_id = @current_company.id
        @user.rights_array = (params[:rights]||{}).keys
        @rights = @user.rights_array        
        return if save_and_redirect(@user)
      else
        role = @current_company.roles.first
        @user = @current_company.users.new(:admin=>false, :role=>role, :employed=>params[:employed])
        @rights = role ? role.rights_array : []
      end
    end
    render_restfully_form
  end

  def create
    if request.xhr? and params[:mode] == "rights"
      role = @current_company.roles.find(params[:user_role_id]) rescue nil
      @rights = role.rights_array if role
      render :partial=>"rights_form"
    else
      if request.post?
        @user = User.new(params[:user])
        @user.company_id = @current_company.id
        @user.rights_array = (params[:rights]||{}).keys
        @rights = @user.rights_array        
        return if save_and_redirect(@user)
      else
        role = @current_company.roles.first
        @user = @current_company.users.new(:admin=>false, :role=>role, :employed=>params[:employed])
        @rights = role ? role.rights_array : []
      end
    end
    render_restfully_form
  end

  def destroy
    return unless @user = find_and_check(:user)
    if request.post? or request.delete? and @user.destroyable?
      @user.destroy
    end
    redirect_to_back
  end

  def lock
    return unless @user = find_and_check(:user)
    if @user
      @user.locked = true
      @user.save
    end
    redirect_to_current
  end
  def unlock
    return unless @user = find_and_check(:user)
    if @user
      @user.locked = false
      @user.save
    end
    redirect_to_current
  end

  def edit
    return unless @user = find_and_check(:user)
    if request.post?
      @user.attributes = params[:user]
      @user.rights_array = (params[:rights]||{}).keys
      @rights = @user.rights_array
      return if save_and_redirect(@user)
    else
      @rights = @user.rights_array
    end
    t3e @user.attributes
    render_restfully_form
  end

  def update
    return unless @user = find_and_check(:user)
    if request.post?
      @user.attributes = params[:user]
      @user.rights_array = (params[:rights]||{}).keys
      @rights = @user.rights_array
      return if save_and_redirect(@user)
    else
      @rights = @user.rights_array
    end
    t3e @user.attributes
    render_restfully_form
  end

  # Displays the main page with the list of users
  def index
  end

end
