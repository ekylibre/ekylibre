class CompanyController < ApplicationController

  def index
    @company = @current_company
    @title = {:value=>@company.name}
  end

  def update
    @company = @current_company
    if request.post?
      if @company.update_attributes(params[:company])
        redirect_to_back
      end
    end
    @title = {:value=>@company.name}
  end

  def backup
    filename = "backup-"+@current_company.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")+".zip"
    stream = "backup "*1000
    #    stream = Zlib::Deflate.deflate(stream)
    Zlib::GzipWriter.open('/tmp/hoge.gz') do |gz|
      gz.write stream
    end
    #send_data stream, :filename=>filename
    send_file '/tmp/hoge.gz'
  end

  def user
    @company = @current_company
    @user = @current_user
    @title = {:value=>@user.label}
  end

  dyta(:users, :conditions=>{:company_id=>['@current_company.id'],:deleted=>false}, :empty=>true) do |t| 
    t.column :name
    t.column :first_name
    t.column :last_name
    t.column :name, :through=>:role
    t.column :free_price
    t.column :credits
    t.column :reduction_percent
    t.column :email
    t.action :locked, :actions=>{"true"=>{:action=>:users_unlock},"false"=>{:action=>:users_lock}}, :method=>:post
#    t.column :locked
#    t.action :users_lock , :image=>:unlock_access , :method=>:post , :confirm=>:sure
#    t.action :users_unlock , :image=>:lock_access , :method=>:post , :confirm=>:sure
    t.action :users_update, :image=>:update 
    t.action :users_delete, :image=>:delete , :method=>:post , :confirm=>:sure
    t.procedure :users_create, :action=>:users_create
  end

  def users
  end

  dyta(:establishments, :conditions=>{:company_id=>['@current_company.id']}, :empty=>true) do |t|
    t.column :name
    t.column :nic
    t.column :siret
    t.column :comment
    t.procedure :establishments_create, :action=>:establishments_create
    t.action :establishments_update, :image=>:update
    t.action :establishments_delete, :image=>:delete , :method=>:post , :confirm=>:sure
  end

  def establishments
  end
  
  dyta(:departments, :conditions=>{:company_id=>['@current_company.id']}, :empty=>true) do |t| 
    t.column :name
    t.column :comment
    t.procedure :departments_create, :action=>:departments_create
    t.action :departments_update, :image=>:update
    t.action :departments_delete, :image=>:delete , :method=>:post , :confirm=>:sure
  end
  dyta(:roles, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
  end


  def departments
  end

  def establishments_create
    access :establishments
    if request.post?
      @establishment = Establishment.new(params[:establishment])
      @establishment.company_id = @current_company.id
      redirect_to_back if @establishment.save
    else
      @establishment = Establishment.new
    end
    render_form
  end
 
  def establishments_update
    access :establishments
    @establishment = Establishment.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @establishment
      if @establishment.update_attributes(params[:establishment])
        redirect_to_back
      end
    end
    render_form
  end

  def establishments_delete
    access :establishments
    if request.post? or request.delete?
      @establishment = Establishment.find_by_id_and_company_id(params[:id], @current_company.id)
      Establishment.delete(params[:id]) if @establishment
    end
    redirect_to_back
  end

  def departments_create
    access :departments
    if request.post? 
      @department = Department.new(params[:department])
      @department.company_id = @current_company.id
      redirect_to_back if @department.save
    else
      @department = Department.new
    end
    render_form
  end

  def departments_update
    access :departments
    @department = Department.find_by_id_and_company_id(params[:id] , @current_company.id)
    if request.post? and @department
      if @department.update_attributes(params[:department])
        redirect_to_back
      end
    end
    render_form
  end

  def departments_delete
    access :departments
    if request.post? or request.delete?
      @department= Department.find_by_id_and_company_id(params[:id] , @current_company.id)
      Department.delete(params[:id]) if @department
    end
    redirect_to_back
  end

  def roles_create
    @role = Role.new
    for right in @@rights
      @rights ||= {}
      @rights[right[0].to_sym] = {}
      @rights[right[0].to_sym] = right[1].values.uniq.collect
    end
    
    if request.post?
      @role = Role.new(params[:role])
      raise Exception.new params.inspect
    end
  end
  
  def users_create
    access :users
    if request.post?
      @user = User.new(params[:user])
      @user.company_id = @current_company.id
      @user.role_id = params[:user][:role_id]
      redirect_to_back if @user.save
    else
      @user = User.new
    end
    render_form
  end

  def users_update
    access :users
    @user= User.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @user
      if @user.update_attributes(params[:user]) 
        redirect_to_back
      end
    end
    render_form
  end
  
  def users_delete
    access :users
    if request.post? or request.delete?
      @user = User.find_by_id_and_company_id(params[:id], @current_company.id)
      if @user
        @user.deleted = true
        @user.save 
      end
    end
    redirect_to_back
  end
  
  def users_lock
    @user = User.find_by_id_and_company_id(params[:id], @current_company.id)
    if @user
      @user.locked = true
      @user.save
    end
    redirect_to_current
  end
  
  def users_unlock
    @user = User.find_by_id_and_company_id(params[:id], @current_company.id)
    if @user
      @user.locked = false
      @user.save
    end
    redirect_to_current
  end
  
end
