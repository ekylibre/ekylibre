class CompanyController < ApplicationController

  def index
    @company = @current_company
    @establishments = @company.establishments
    @departments = @company.departments
    @users = @company.users
  end

  def update
    @company = @current_company
    if request.post?
      if @company.update_attributes(params[:company])
        redirect_to :action=>:index  
      end
    end
  end

  def user
    @company = @current_company
    @user = @current_user
  end

  dyta(:users, :conditions=>{:company_id=>['@current_company.id'],:deleted=>false}) do |t|
    t.column :name
    t.column :first_name
    t.column :last_name
    t.column :email
   # t.column :locked
    t.procedure :users_create, :action=>:users_create
    t.action :users_update, :image=>:update 
    t.action :users_delete, :image=>:delete , :method=>:post , :confirm=>:sure

  end

  def users
    users_list params
  end

  dyta(:establishments, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :nic
    t.column :siret
    t.column :note
    t.procedure :establishments_create, :action=>:establishments_create
    t.action :establishments_update, :image=>:update
    t.action :establishments_delete, :image=>:delete , :method=>:post , :confirm=>:sure
  end

  def establishments
    establishments_list params
  end
  
  dyta(:departments, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :desc
    t.procedure :departments_create, :action=>:departments_create
    t.action :departments_update, :image=>:update
    t.action :departments_delete, :image=>:delete , :method=>:post , :confirm=>:sure
  end

  def departments
    departments_list params
  end

  def establishments_create
    access :establishments
    if request.post?
      @establishment = Establishment.new(params[:establishment])
      @establishment.company_id = session[:company_id]
      redirect_to :action=>:establishments if @establishment.save
    else
      @establishment = Establishment.new
    end
    render_form
  end
 
  def establishments_update
    access :establishments
    @establishment = Establishment.find(params[:id])
    if request.post?
      if @establishment.update_attributes(params[:establishment])
        redirect_to :action=>:establishments
      end
    end
    render_form
  end

  def establishments_delete
    access :establishments
    Establishment.delete(params[:id])
    redirect_to :action=>:establishments
  end

  def departments_create
    access :departments
    if request.post?
      @department = Department.new(params[:department])
      @department.company_id = session[:company_id]
      redirect_to :action=>:departments if @department.save
    else
      @department = Department.new
    end
    render_form
  end

  def departments_update
    access :departments
    @department = Department.find(params[:id])
    if request.post?
      if @department.update_attributes(params[:department])
        redirect_to :action=>:departments
      end
    end
    render_form
  end

  def departments_delete
    access :departments
    Department.delete(params[:id])
    redirect_to :action=>:departments
  end

  def users_create
    access :users
    if request.post?
      @user = User.new(params[:user])
      @user.company_id = session[:company_id]
      @user.role_id = params[:user][:role_id]
      redirect_to :action=>:users if @user.save
    else
      @user = User.new
    end
    render_form
  end

  def users_update
    access :users
    @user= User.find(params[:id])
    if request.post?
      if @user.update_attributes(params[:user]) 
        redirect_to :action=>:users
      end
    end
    render_form
  end
  
  def users_delete
    access :users
    User.delete(params[:id])
    redirect_to :action=>:users
   # @user.id = params[:id]
   #  @user.deleted = true
  end

  def users_lock
    @user.id = param[:id]
    @user.locked = true
  end

end

