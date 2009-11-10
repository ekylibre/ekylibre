class ResourcesController < ApplicationController

  def index
    @employees = @current_company.employees
  end

  dyta(:employees, :conditions=>search_conditions(:employees, :employees=>[:id, :title, :first_name, :last_name]), :order=>:last_name, :empty=>true) do |t|
    t.column :title 
    t.column :first_name 
    t.column :last_name 
    t.column :name, :through=>:user  
    t.action :employee_update
    t.action :employee_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  # Lists all the employees with main informations for each of them.
  def employees
    @key = params[:key]||session[:employee_key]
    session[:employee_key] = @key
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
