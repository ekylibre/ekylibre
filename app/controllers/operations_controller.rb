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

class OperationsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>" planned_on desc, name asc") do |t|
    t.column :name, :url=>true
    t.column :name, :through=>:nature
    t.column :label, :through=>:responsible, :url=>true
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :name, :through=>:target
    t.column :duration
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of operations
  def index
  end


  list(:uses, :model=>:operation_uses, :conditions=>{:company_id=>['@current_company.id'], :operation_id=>['session[:current_operation_id]']}, :order=>"id") do |t|
    t.column :name, :through=>:tool, :url=>true
  end

  list(:lines, :model=>:operation_lines, :conditions=>{:company_id=>['@current_company.id'], :operation_id=>['session[:current_operation_id]']}, :order=>"direction") do |t|
    t.column :direction_label
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:product, :url=>true
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:tracking, :url=>true
    t.column :density_label
  end


  # Displays details of one operation selected with +params[:id]+
  def show
    return unless @operation = find_and_check(:operation)
    session[:current_operation_id] = @operation.id
    t3e @operation.attributes
  end

  def new
    if request.post?
      # raise params.inspect
      @operation = @current_company.operations.new(params[:operation])
      @operation_lines = (params[:lines]||{}).values
      @operation_uses = (params[:uses]||{}).values
      redirect_to_back if @operation.save_with_uses_and_lines(@operation_uses, @operation_lines)
    else
      @operation = Operation.new(:planned_on=>params[:planned_on]||Date.today, :target_id=>params[:target_id].to_i, :responsible_id=>@current_user.id, :hour_duration=>2, :min_duration=>0)
    end
    render_restfully_form
  end

  def create
    if request.post?
      # raise params.inspect
      @operation = @current_company.operations.new(params[:operation])
      @operation_lines = (params[:lines]||{}).values
      @operation_uses = (params[:uses]||{}).values
      redirect_to_back if @operation.save_with_uses_and_lines(@operation_uses, @operation_lines)
    else
      @operation = Operation.new(:planned_on=>params[:planned_on]||Date.today, :target_id=>params[:target_id].to_i, :responsible_id=>@current_user.id, :hour_duration=>2, :min_duration=>0)
    end
    render_restfully_form
  end

  def destroy
    return unless @operation = find_and_check(:operations)
    @operation.destroy if request.post? or request.delete?
    redirect_to_current
  end

  def edit
    return unless @operation = find_and_check(:operations)
    session[:tool_ids] = []
    for tool in @operation.tools
      session[:tool_ids] << tool.id.to_s
    end
    if request.post?
      @operation.attributes = params[:operation]
      @operation_lines = (params[:lines]||{}).values
      @operation_uses = (params[:uses]||{}).values
      redirect_to_back if @operation.save_with_uses_and_lines(@operation_uses, @operation_lines)
    end
    t3e @operation.attributes
    render_restfully_form
  end

  def update
    return unless @operation = find_and_check(:operations)
    session[:tool_ids] = []
    for tool in @operation.tools
      session[:tool_ids] << tool.id.to_s
    end
    if request.post?
      @operation.attributes = params[:operation]
      @operation_lines = (params[:lines]||{}).values
      @operation_uses = (params[:uses]||{}).values
      redirect_to_back if @operation.save_with_uses_and_lines(@operation_uses, @operation_lines)
    end
    t3e @operation.attributes
    render_restfully_form
  end


  list(:unvalidateds, :model=>:operations, :conditions=>{:moved_on=>nil, :company_id=>['@current_company.id']}) do |t|
    t.column :name 
    t.column :name, :through=>:nature
    t.column :label, :through=>:responsible, :url=>true
    t.column :name, :through=>:target
    t.column :planned_on
    t.text_field :moved_on, :value=>'Date.today', :size=>10
    t.check_box :validated, :value=>'RECORD.planned_on<=Date.today'
  end

  def unvalidateds
    @operations = @current_company.operations.find(:all, :conditions=>{:moved_on=>nil})
    notify_now(:no_unvalidated_operations) if @operations.size <= 0
    if request.post?
      for id, values in params[:unvalidated_operations]
        operation = @current_company.operations.find_by_id(id)
        operation.make((values[:moved_on].to_date rescue Date.today)) if operation and values[:validated].to_i == 1
        #operation.update_attributes!(:moved_on=>Date.today) if operation and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidateds
    end
  end


end
