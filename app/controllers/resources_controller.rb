class ResourcesController < ApplicationController

  def index
    @employees = @current_company.employees
  end


  dyta(:employees, :conditions=>search_conditions(:employees, :employees=>[:id, :title, :first_name, :last_name]), :empty=>true) do |t|
    t.column :title 
    t.column :first_name 
    t.column :last_name 
    t.column :name, :through=>:user  
    t.action :employees_update, :image=>:update
    t.action :employees_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:professions, :conditions=>{:company_id=>['@current_company.id']}, :empty=>true) do |t|
    t.column :name 
    t.column :code 
    t.column :rome 
    t.column :commercial
    t.action :professions_update, :image=>:update
    t.action :professions_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  # this action lists all the employees with main informations for each of them.
  def employees
    @key = params[:key]||session[:product_key]
    session[:employee_key] = @key
    # employees_list
  end
  
  # this action creates an employee with a form.
  def employees_create    
    if request.post?
      @employee = Employee.new(params[:employee])
      @employee.company_id = @current_company.id
      redirect_to_back if @employee.save
    else
      @employee  = Employee.new
    end
    render_form
  end

  # this action updates an existing employee with a form.
  def employees_update
    @employee = @current_company.employees.find_by_id(params[:id])
    # @employee = Employee.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      redirect_to_back if @employee.update_attributes(params[:employee])
    end
    # @title = {:value=>@account.label}
    render_form 
  end

  # this action deletes or hides an existing employee.
  def employees_delete
    if request.post? or request.delete?
      @employee = @current_company.employees.find_by_id(params[:id])
      # @employee = Employee.find_by_id_and_company_id(params[:id], @current_company.id)  
      Employee.destroy(@employee.id) if @employee
    end
    redirect_to_current
  end

  # this action lists all the professions with main informations for each of them.  
  def professions
    # professions_list params
  end

  # this action creates a profession with a form.
  def professions_create
    if request.post?
      @profession = Profession.new(params[:profession])
      @profession.company_id = @current_company.id
      redirect_to_back if @profession.save
    else
      @profession  = Profession.new
    end
    render_form
  end

  # this action updates an existing employee with a form.
  def professions_update
    @profession = @current_company.professions.find_by_id(params[:id])
    if request.post? or request.put?
      redirect_to_back if @profession.update_attributes(params[:profession])
    end
    render_form 
  end

  # this action deletes or hides an existing employee.
  def professions_delete
    if request.post? or request.delete?
      @profession = @current_company.professions.find_by_id(params[:id])
      Profession.destroy(@profession.id) if @profession
    end
    redirect_to_current
  end


end
