class ResourcesController < ApplicationController

  dyta(:employees, :conditions=>:search_conditions, :empty=>true) do |t|
    t.column :title 
    t.column :first_name 
    t.column :last_name 
    t.action :employees_update, :image=>:update
    t.action :employees_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :create, :action=>:employees_create
  end

  # lists all the employees with main informations for each of them.
  def employees
    employees_list params
  end
  
  # this action creates an employee with a form.
  def employees_create
  access :employees
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
    access :employees
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
    access :employees
    if request.post? or request.delete?
      @employee = @current_company.employees.find_by_id(params[:id])
      # @employee = Employee.find_by_id_and_company_id(params[:id], @current_company.id)  
      Employee.destroy(@employee.id) if @employee
    end
    redirect_to_current
  end

end
