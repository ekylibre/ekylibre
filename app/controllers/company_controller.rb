require "rexml/document"

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
    company = @current_company

    filename = "backup-"+@current_company.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")+".zes"
    file = "#{RAILS_ROOT}/tmp/#{filename}"
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new
    root = doc.add_element 'company'
    reflections = Company.reflections
    for name in reflections.keys.collect{|x| x.to_s}.sort
      reflection = reflections[name.to_sym]
      if reflection.macro==:has_many
        klass = reflection.class_name.constantize
        table = root.add_element('table', 'name'=>name, 'model'=>klass.to_s)
        label = I18n.translate("activerecord.models.#{klass.to_s.underscore}")
        table.add_attribute 'label', label unless label.match /^translation\ missing/
        columns = klass.column_names.sort
        for x in company.send(name.to_sym)
          puts x.id if x.id%200==0
          record = table.add_element('record', x.attributes)
          #columns.each do |c|
          # record.add_attribute c, x.send(c).to_s
          #end
        end
      end
    end

    stream = doc.to_s #"backup "*1000
    # send_data stream, :filename=>filename, :disposition=>'inline', :type=>'text'
    send_data Zlib::Deflate.deflate(stream), :filename=>filename
    # Zlib::GzipWriter.open(file) { |gz| gz.write(stream) }
    # send_file file
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
    t.column :admin
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
    t.action :roles_update
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
     # raise Exception.new params.inspect
      @role.company_id = @current_company.id
      @role.rights = "administrate_nothing "
      for right in params[:right]
        @role.rights += right[0].to_s+" "
      end
      #raise Exception.new   @role.rights.inspect
      redirect_to_back if @role.save
    end
  end
  
  def users_create
    access :users
    if request.post?
     # raise Exception.new params.inspect
      @user = User.new(params[:user])
      @user.company_id = @current_company.id
      @user.role_id = params[:user][:role_id]
      @user.rights = "administrate_nothing "
      for right in params[:right]
        @user.rights += right[0].to_s+" "
      end
      redirect_to_back if @user.save
    else
      @user = User.new
      @role = Role.find_by_name_and_company_id("Administrateur", @current_company.id)
      for right in @@rights
        @rights ||= {}
        @rights[right[0].to_sym] = {}
        @rights[right[0].to_sym] = right[1].values.uniq.collect
      end
      @rights.delete_if {|key,value| (key.to_s=="search" or key.to_s=="guide" or key.to_s=="authentication" or key.to_s=="help") }
      #raise Exception.new @rights.inspect
      #raise Exception.new @role.inspect
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
