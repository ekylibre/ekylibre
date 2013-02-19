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

class Backend::OperationsController < BackendController
  manage_restfully :planned_on => "params[:planned_on]||Date.today", :target_id => "params[:target_id].to_i", :hour_duration => "2", :min_duration => "0"

  unroll_all

  list(:order => "planned_on DESC, name ASC") do |t|
    t.column :name, :url => true
    t.column :nature
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :name, :through => :target
    t.column :duration
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of operations
  def index
  end


  # list(:uses, :model => :operation_uses, :conditions => {:operation_id => ['session[:current_operation_id]']}, :order => "id") do |t|
  #   t.column :name, :through => :tool, :url => true
  # end

  # list(:items, :model => :operation_items, :conditions => {:operation_id => ['session[:current_operation_id]']}, :order => "direction") do |t|
  #   t.column :direction
  #   # t.column :name, :through => :warehouse, :url => true
  #   t.column :name, :through => :product, :url => true
  #   t.column :quantity
  #   t.column :label, :through => :unit
  #   t.column :serial_number, :through => :product
  #   t.column :density_label
  # end


  # Displays details of one operation selected with +params[:id]+
  def show
    return unless @operation = find_and_check(:operation)
    session[:current_operation_id] = @operation.id
    t3e @operation.attributes
  end

  # def new
  #   @operation = Operation.new(:planned_on => params[:planned_on]||Date.today, :target_id => params[:target_id].to_i, :responsible_id => @current_user.id, :hour_duration => 2, :min_duration => 0)
  #   # render_restfully_form
  # end

  # def create
  #   @operation = Operation.new(params[:operation])
  #   @operation_items = (params[:items]||{}).values
  #   @operation_uses = (params[:uses]||{}).values
  #   redirect_to_back and return if @operation.save_with_uses_and_items(@operation_uses, @operation_items)
  #   # render_restfully_form
  # end

  # def destroy
  #   return unless @operation = find_and_check(:operations)
  #   @operation.destroy
  #   redirect_to_current
  # end

  # def edit
  #   return unless @operation = find_and_check(:operations)
  #   session[:tool_ids] = []
  #   for tool in @operation.tools
  #     session[:tool_ids] << tool.id.to_s
  #   end
  #   t3e @operation.attributes
  #   # render_restfully_form
  # end

  # def update
  #   return unless @operation = find_and_check(:operations)
  #   session[:tool_ids] = []
  #   for tool in @operation.tools
  #     session[:tool_ids] << tool.id.to_s
  #   end
  #   @operation.attributes = params[:operation]
  #   @operation_items = (params[:items]||{}).values
  #   @operation_uses = (params[:uses]||{}).values
  #   if @operation.save_with_uses_and_items(@operation_uses, @operation_items)
  #     redirect_to_back
  #     return
  #   end
  #   t3e @operation.attributes
  #   # render_restfully_form
  # end


  list(:unvalidateds, :model => :operations, :conditions => {:confirmed => false}, :order => "id DESC") do |t|
    t.column :name
    t.column :nature
    t.column :name, :through => :target
    t.column :planned_on
    t.text_field :moved_on, :value => 'Date.today', :size => 10
    t.check_box :validated, :value => 'RECORD.planned_on<=Date.today'
  end

  def unvalidateds
    @operations = Operation.where(:moved_on  =>  nil)
    notify_now(:no_unvalidated_operations) if @operations.count.zero?
    if request.post?
      for id, values in params[:unvalidateds]
        operation = Operation.find_by_id(id)
        operation.make((values[:moved_on].to_date rescue Date.today)) if operation and values[:validated].to_i == 1
        #operation.update_attributes!(:moved_on => Date.today) if operation and values[:validated].to_i == 1
      end
      redirect_to :action => :unvalidateds
    end
  end


end
