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

class ProductionController < ApplicationController

  def index
    @operations = @current_company.operations.find(:all, :conditions=>{:moved_on=>nil})
  end

 
  dyta(:tools,  :conditions=>{:company_id=>['@current_company.id']}, :order=>"name") do |t|
    t.column :name, :url=>{:action=>:tool}
    t.column :text_nature
    t.column :consumption
    t.action :tool_update
    t.action :tool_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.uses.size == 0'
  end

  def tools
  end

  dyta(:tool_operations, :model=>:operation_uses, :conditions=>{:company_id=>['@current_company.id'], :tool_id=>['session[:current_tool]']}, :order=>"created_at ASC") do |t|
    t.column :name,       :through=>:operation, :label=>:column, :url=>{:action=>:operation}
    t.column :planned_on, :through=>:operation, :label=>:column, :datatype=>:date
    t.column :moved_on,   :through=>:operation, :label=>:column
    t.column :tools_list, :through=>:operation, :label=>:column
    t.column :duration,   :through=>:operation, :label=>:column
  end
  
  def tool
    return unless @tool = find_and_check(:tools)
    session[:current_tool] = @tool.id
    t3e @tool.attributes
  end
  
  manage :tools

  
  dyta(:land_parcels, :conditions=>["company_id=? AND ? BETWEEN started_on AND COALESCE(stopped_on, ?)", ['@current_company.id'], ['session[:viewed_on]'], ['session[:viewed_on]']], :order=>"name") do |t|
    t.column :name, :url=>{:action=>:land_parcel}
    t.column :number
    t.column :area_measure, :datatype=>:decimal
    t.column :name, :through=>:area_unit
    t.column :name, :through=>:group, :url=>{:action=>:land_parcel_group}
    t.column :description
    t.column :started_on
    t.column :stopped_on
    t.action :land_parcel_divide
    t.action :land_parcel_update
    t.action :land_parcel_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def land_parcels
    session[:viewed_on] = (params[:viewed_on]||session[:viewed_on]).to_date rescue Date.today
  end

  manage :land_parcels, :started_on=>"Date.today"

  def land_parcel_divide
    return unless @land_parcel = find_and_check(:land_parcel)
    if request.xhr?
      render :partial=>"land_parcel_subdivision_form"
      return
    end

    if request.post?
      if @land_parcel.divide(params[:subdivisions].values, params[:land_parcel][:stopped_on].to_date)
        redirect_to :action=>:land_parcels
      end
    end
    @land_parcel.stopped_on ||= (session[:viewed_on].to_date rescue Date.today) - 1
    t3e @land_parcel.attributes
  end


  dyta(:land_parcel_operations, :model=>:operations,  :conditions=>{:company_id=>['@current_company.id'], :target_type=>LandParcel.name, :target_id=>['session[:current_land_parcel]']}, :order=>"planned_on ASC") do |t|
    t.column :name, :url=>{:action=>:operation}
    t.column :name, :through=>:nature
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :duration
    t.action :operation_update
    t.action :operation_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end


  def land_parcel
    return unless @land_parcel = find_and_check(:land_parcels)
    session[:current_land_parcel] = @land_parcel.id
    t3e @land_parcel.attributes
  end

  def land_parcels_map
    @map = true
  end


  dyta(:land_parcel_groups, :conditions=>{:company_id=>['@current_company.id']}, :order=>"name") do |t|
    t.column :name
    t.column :color
    t.column :comment
    t.action :land_parcel_group_update
    t.action :land_parcel_group_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  
  def land_parcel_groups
  end

  manage :land_parcel_groups

  
  dyta(:operations, :conditions=>{:company_id=>['@current_company.id']}, :order=>" planned_on desc, name asc") do |t|
    t.column :name, :url=>{:action=>:operation}
    t.column :name, :through=>:nature
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :name, :through=>:target
    t.column :duration
    t.action :operation_update, :image=>:update
    t.action :operation_delete, :method=>:delete, :image=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def operations
  end

  dyta(:operation_lines, :conditions=>{:company_id=>['@current_company.id'], :operation_id=>['session[:current_operation_id]']}, :order=>"direction") do |t|
    t.column :direction_label
    t.column :name, :through=>:warehouse, :url=>{:controller=>:management, :action=>:warehouse}
    t.column :name, :through=>:product, :url=>{:controller=>:management, :action=>:product}
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:tracking, :url=>{:controller=>:management, :action=>:tracking}
    t.column :density_label
  end

  dyta(:operation_uses, :conditions=>{:company_id=>['@current_company.id'], :operation_id=>['session[:current_operation_id]']}, :order=>"id") do |t|
    t.column :name, :through=>:tool, :url=>{:action=>:tool}
  end

  def operation
    return unless @operation = find_and_check(:operation)
    session[:current_operation_id] = @operation.id
    t3e @operation.attributes
  end
  
  def operation_create
    if request.post?
      # raise params.inspect
      @operation = @current_company.operations.new(params[:operation])
      @operation_lines = (params[:lines]||{}).values
      @operation_uses = (params[:uses]||{}).values
      redirect_to_back if @operation.save_with_uses_and_lines(@operation_uses, @operation_lines)
    else
      @operation = Operation.new(:planned_on=>params[:planned_on]||Date.today, :target_id=>params[:target_id].to_i, :responsible_id=>@current_user.id, :hour_duration=>2, :min_duration=>0)
    end
    render_form
  end

  def operation_update
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
    render_form
  end

  def operation_delete
    return unless @operation = find_and_check(:operations)
    @operation.destroy if request.post? or request.delete?
    redirect_to_current
  end

  dyli(:operation_products, [:code, :name], :model=>:products, :conditions => {:company_id=>['@current_company.id'], :active=>true})
  # dyli(:operation_out_products, [:code, :name], :model=>:products, :conditions => {:company_id=>['@current_company.id'], :active=>true, :to_produce=>true})

  def operation_line_create
    if request.xhr?
      render :partial=>'operation_line_row_form'
    else
      redirect_to :action=>:index
    end
  end


  def operation_use_create
    if request.xhr?
      render :partial=>'operation_use_row_form'
    else
      redirect_to :action=>:index
    end
  end


  dyta(:operation_natures, :conditions=>{:company_id=>['@current_company.id']}, :order=>"name" ) do |t|
    t.column :name
    t.column :description
    t.action :operation_nature_update
    t.action :operation_nature_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def operation_natures
  end

  manage :operation_natures



  dyta(:unvalidated_operations, :model=>:operations, :conditions=>{:moved_on=>nil, :company_id=>['@current_company.id']}) do |t|
    t.column :name 
    t.column :name, :through=>:nature
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
    t.column :name, :through=>:target
    t.column :planned_on
    t.textbox :moved_on, :value=>'Date.today', :size=>10
    t.check :validated, :value=>'RECORD.planned_on<=Date.today'
  end

  def unvalidated_operations
    @operations = @current_company.operations.find(:all, :conditions=>{:moved_on=>nil})
    notify(:no_unvalidated_operations, :now) if @operations.size <= 0
    if request.post?
      for id, values in params[:unvalidated_operations]
        operation = @current_company.operations.find_by_id(id)
        operation.make((values[:moved_on].to_date rescue Date.today)) if operation and values[:validated].to_i == 1
        #operation.update_attributes!(:moved_on=>Date.today) if operation and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidated_operations
    end
  end


  dyta(:production_chains, :conditions=>{:company_id=>['@current_company.id']}, :order=>"name" ) do |t|
    t.column :name, :url=>{:action=>:production_chain}
    t.column :comment
    t.action :production_chain_play
    t.action :production_chain_update
    t.action :production_chain_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end


  def production_chains
  end

  manage :production_chains

  dyta(:production_chain_operations, :conditions=>{:company_id=>['@current_company.id']}, :order=>"name" ) do |t|
    t.column :name, :url=>{:action=>:production_chain_operation}
    t.column :name, :through=>:operation_nature
    t.column :nature
    t.column :name, :through=>:building, :url=>{:controller=>:management, :action=>:warehouse}
    t.column :comment
    t.action :production_chain_operation_update
    t.action :production_chain_operation_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  dyta(:production_chain_conveyors, :conditions=>{:company_id=>['@current_company.id']}, :order=>"id" ) do |t|
    t.column :name, :through=>:product, :url=>{:controller=>:management, :action=>:product}
    t.column :flow
    t.column :name, :through=>:unit
    t.column :name, :through=>:source, :url=>{:action=>:production_chain_operation}
    t.column :name, :through=>:target, :url=>{:action=>:production_chain_operation}
    t.action :production_chain_conveyor_update
    t.action :production_chain_conveyor_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def production_chain
    return unless @production_chain = find_and_check(:production_chain)
    t3e @production_chain.attributes
  end


  def production_chain_play
    return unless @production_chain = find_and_check(:production_chain)
    if params[:operation_id]
      return unless @production_chain_operation = find_and_check(:production_chain_operation, params[:operation_id])
    end
    if request.xhr? and @production_chain_operation
      render :partial=>"production_chain_operation_inputs", :object=>@production_chain_operation
    end
    t3e @production_chain.attributes
  end


  manage :production_chain_operations, :production_chain_id=>"params[:production_chain_id]", :nature=>"(params[:nature]||'input')"

  def production_chain_operation
    return unless @production_chain_operation = find_and_check(:production_chain_operation)
    t3e @production_chain_operation.attributes
  end

  def production_chain_operation_up
    return unless @production_chain_operation = find_and_check(:production_chain_operation)
    if request.post?
      @production_chain_operation.move_higher
    end
    redirect_to_current
  end

  def production_chain_operation_down
    return unless @production_chain_operation = find_and_check(:production_chain_operation)
    if request.post?
      @production_chain_operation.move_lower
    end
    redirect_to_current
  end

  manage :production_chain_conveyors, :production_chain_id=>"params[:production_chain_id]", :source_id=>"params[:source_id]", :target_id=>"params[:target_id]"

end
