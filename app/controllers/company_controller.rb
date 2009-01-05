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
        redirect_to :action=>:company
      end
    end
  end

  def user
    @company = @current_company
    @user = @current_user
  end

  dyta(:users, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :first_name
    t.column :last_name
    t.column :email
  end

  def users
    users_list params
  end

  dyta(:establishments, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :nic
    t.column :siret
    t.column :note
  end

  def establishments
    establishments_list params
  end
  
  dyta(:departments, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :desc
  end

  def departments
    departments_list params
  end

  def users_create
    access :users
    if request.post?
      @user = User.new(params[:user])
      @user.company_id = session[:company_id]
      redirect_to session[:url][1] if @user.save
    else
      @user = User.new
    end
    render_form
  end

  def users_update
  end
  
end

