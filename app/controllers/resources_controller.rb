class ResourcesController < ApplicationController

  def index
    @employees = @current_company.employees
  end

  dyta(:employees, :conditions=>search_conditions(:employees, :employees=>[:id, :title, :first_name, :last_name]), :order=>:last_name, :empty=>true) do |t|
    t.column :title 
    t.column :first_name, :url=>{:action=>:employee}
    t.column :last_name , :url=>{:action=>:employee}
    t.column :name, :through=>:user  
    t.action :employee_update
    t.action :employee_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  # Lists all the employees with main informations for each of them.
  def employees
    @key = params[:key]||session[:employee_key]
    session[:employee_key] = @key
  end

  dyta(:employee_events, :model=>:events, :conditions=>{:company_id=>['@current_company.id'], :employee_id=>['session[:current_employee]']}, :order=>'started_at desc') do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity}
    t.column :duration
    t.column :location
    t.column :name, :through=>:nature
    t.column :started_at
    t.action :event_update, :controller=>:relations
    t.action :event_delete, :controller=>:relations, :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:employee_sale_orders, :model=>:sale_orders, :conditions=>{:company_id=>['@current_company.id'], :responsible_id=>['session[:current_employee]']}, :order=>'created_on desc') do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:sale_order_lines}
    t.column :created_on
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}
    t.column :code, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}, :label=>tc('client_code')
    t.column :text_state
    t.column :amount
    t.column :amount_with_taxes
    t.action :print, :url=>{:controller=>:company, :type=>:sale_order}
    t.action :sale_order_delete ,:controller=>:management,  :method=>:post, :if=>'RECORD.estimate? ', :confirm=>:are_you_sure
  end
  
  def employee
    return unless @employee = find_and_check(:employees, params[:id])
    session[:current_employee] = @employee.id
    @title = {:label=>@employee.label}
  end

  manage :employees

  dyta(:professions, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name, :empty=>true) do |t|
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
