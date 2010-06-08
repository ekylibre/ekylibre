# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
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

class ResourcesController < ApplicationController

  def index
    @employees = @current_company.employees
  end

  # search_conditions(:users, [:id, :title, :first_name, :last_name])
  dyta(:employees, :model=>:users, :conditions=>{:employed=>true}, :order=>:last_name) do |t|
    t.column :last_name , :url=>{:action=>:employee}
    t.column :first_name, :url=>{:action=>:employee}
    t.column :employment
    t.column :arrived_on
    t.column :departed_on
    t.action :user_update, :url=>{:controller=>:company}
    t.action :employee_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  # Lists all the employees with main informations for each of them.
  def employees
  end
  
  dyta(:employee_events, :model=>:events, :conditions=>{:company_id=>['@current_company.id'], :user_id=>['session[:current_employee]']}, :order=>'started_at desc') do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity}
    t.column :duration
    t.column :location
    t.column :name, :through=>:nature
    t.column :started_at
    t.action :event_update, :controller=>:relations
    t.action :event_delete, :controller=>:relations, :method=>:delete, :confirm=>:are_you_sure
  end

  dyta(:employee_sale_orders, :model=>:sale_orders, :conditions=>{:company_id=>['@current_company.id'], :responsible_id=>['session[:current_employee]']}, :order=>'created_on desc') do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:sale_order_lines}
    t.column :created_on
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}
    t.column :code, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}, :label=>tc('client_code')
    t.column :text_state
    t.column :amount
    t.column :amount_with_taxes
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:sale_order}
    t.action :sale_order_delete ,:controller=>:management,  :method=>:delete, :if=>'RECORD.estimate? ', :confirm=>:are_you_sure
  end

   dyta(:employee_shape_operations, :model=>:operations, :conditions=>{:company_id=>['@current_company.id'], :responsible_id=>['session[:current_employee]']}, :order=>'planned_on desc, name asc') do |t|
    t.column :name, :url=>{:action=>:operation, :controller=>:production}
    t.column :name, :through=>:nature
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :duration
    t.action :operation_update, :image=>:update,:controller=>:production
    t.action :operation_delete, :method=>:delete, :image=>:delete, :confirm=>:are_you_sure,:controller=>:production
  end
  
  def employee
    return unless @user = find_and_check(:users)
    session[:current_employee] = @user.id
    @title = {:label=>@user.label}
  end

  def employee_delete
    return unless @user = find_and_check(:users)
    if request.post? or request.delete?
      @user.employed = false
      @user.save
    end
    redirect_to_current
  end




  # manage :employees

  dyta(:professions, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name 
    t.column :code 
    t.column :rome 
    t.column :commercial
    t.action :profession_update
    t.action :profession_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  # Lists all the professions with main informations for each of them.
  def professions
  end

  manage :professions

end
