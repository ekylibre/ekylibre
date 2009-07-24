require "rexml/document"
require "zlib"

class CompanyController < ApplicationController
  include ApplicationHelper

  @@helps = {}
  for file in Dir["#{RAILS_ROOT}/config/locales/#{I18n.locale}/help/*.txt"].sort
    File.open(file, 'rb') do |f| 
      @@helps[file] = {:title=>f.read[/^h1.\s*(.*)\s*$/, 1], :name=>file.split(/[\\\/\.]+/)[-2]}
      raise Exception.new("No good title for #{file}") if @@helps[file][:title].blank?
    end
  end

  def index
    @title = {:user=>@current_user.label}
    @entities = @current_company.entities
    @deliveries = @current_company.deliveries.find(:all,:conditions=>{:moved_on=>nil})
    @purchases = @current_company.purchase_orders.find(:all, :conditions=>{:moved_on=>nil})
  end

  def welcome
    redirect_to :action=>:index
  end

  def unknown_action
    flash[:error] = tc(:unknown_action, :value=>request.url.inspect)
    redirect_to :action=>:index
  end
  
  def about_us
    File.open("#{RAILS_ROOT}/VERSION") {|f| @version = f.read.split(',')}
    begin
      @properties = Rails::Info.properties.dup
    rescue
      @properties = []
    end
    @properties.reverse!
    @properties.insert(0, ["Ekylibre version", @version.reverse.join(' / ')])
  end

  def help
    @per_page = 15
    if request.xhr?
      render :text=>article(params[:article], :url=>{:controller=>:company, :action=>:help, :article=>'\1'}, :update=>:helpage)
    else
      @key = params[:key]||session[:help_key]
      session[:help_key] = @key
      @key_words = @key.to_s.lower.split(" ").select{|x| x.strip.length>2}
      reg = /(#{@key_words.join("|")})/i
      if @key_words.size>0
        @results = []
        for file in @@helps.keys
          File.open(file) do |f| 
            data = f.read
            if (match = data.scan(reg).size) > 0
              @results << @@helps[file].merge(:count=>match) 
            end
          end
        end
        if @results.size>0
          @results.sort!{|a,b| b[:count]<=>a[:count]}
          max = @results[0][:count]
          @results.each{|r| r[:pertinence] = (100*r[:count]/max).to_i}
        end
      end
    end
  end

  def configure
    @company = @current_company
    @tree = Parameter.tree_reference.sort
    for k, v in @tree
      for name, options in v
        param = @company.parameter(name)
        if param
          options[:value] = param.value 
          options[:value] = options[:value].id if param.record? and options[:value]
        end
        options[:value] ||= options[:default]
      end
    end
    if request.post?
      saved = false
      ActiveRecord::Base.transaction do
        saved = @company.update_attributes(params[:company])
        if saved
          for key, data in params[:parameter]
            parameter = @company.parameters.find_by_name(key)
            parameter = @company.parameters.build(:name=>key) if parameter.nil?
            parameter.value = data[:value]
            unless parameter.save
              saved = false
              parameter.errors.each_full do |msg|
                @company.errors.add_to_base(msg)
              end
              raise ActiveRecord::Rollback
            end
          end
        end
      end
      redirect_to_back if saved
    end
    @title = {:value=>@company.name}
  end

  def backup
    send_file(@current_company.backup(@current_user))
  end


  def restore
    if request.post?
      company = @current_company
      # Récupération du fichier
      backup = params[:backup][:path]
      file = "#{RAILS_ROOT}/tmp/uploads/#{backup.original_filename}.#{rand.to_s[2..-1].to_i.to_s(36)}"
      File.open(file, "w") { |f| f.write(backup.read)}
      old_code = company.code
      start = Time.now.to_i
      if @current_company.restore(file)
        @new_code = company.code if old_code!=company.code
        flash.now[:notice] = tc(:restoration_finished, :value=>(Time.now.to_i-start).to_s)
      else
        flash.now[:error] = tc(:unvalid_version_for_restore)
      end
    end
  end
  






  dyta(:establishments, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :nic
    t.column :siret
    t.column :comment
    t.action :establishments_update
    t.action :establishments_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def establishments
  end
  
  def establishments_create
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
    @establishment = Establishment.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @establishment
      if @establishment.update_attributes(params[:establishment])
        redirect_to_back
      end
    end
    render_form
  end

  def establishments_delete
    if request.post? or request.delete?
      @establishment = Establishment.find_by_id_and_company_id(params[:id], @current_company.id)
      Establishment.destroy(params[:id]) if @establishment
    end
    redirect_to_back
  end



  dyta(:departments, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :comment
    t.action :departments_update
    t.action :departments_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def departments
  end

  def departments_create
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
    @department = Department.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @department
      if @department.update_attributes(params[:department])
        redirect_to_back
      end
    end
    render_form
  end

  def departments_delete
    if request.post? or request.delete?
      @department= Department.find_by_id_and_company_id(params[:id], @current_company.id)
      Department.destroy(params[:id]) if @department
    end
    redirect_to_back
  end





  dyta(:roles, :conditions=>{:company_id=>['@current_company.id']}, :children=>:users) do |t| 
    t.column :name, :children=>:label
    t.column :diff_more, :class=>'rights more'
    t.column :diff_less, :class=>'rights less'
    t.action :roles_update
    t.action :roles_delete, :method=>:post, :confirm=>:are_you_sure, :if=>"RECORD.destroyable\?"
  end

  def roles
  end

  def roles_create
    @role = Role.new
    if request.post?
      @role = Role.new(params[:role])
      @role.company_id = @current_company.id
      @role.rights_array = (params[:rights]||{}).keys
      @rights = @role.rights_array
      redirect_to_back if @role.save
    else
      @rights = User.rights_list      
    end
    render_form
  end

  def roles_update
    @role = find_and_check(:role, params[:id])
    if request.post?
      @role.attributes = params[:role]
      @role.rights_array = (params[:rights]||{}).keys
      @rights = @role.rights_array
      redirect_to_back if @role.save
    else
      @rights = @role.rights_array
    end
    @title = {:value=>@role.name}
    render_form
  end

  def roles_delete
    if request.post? or request.delete?
      @role = Role.find_by_id_and_company_id(params[:id], @current_company.id)
      Role.destroy(@role.id) if @role and @role.destroyable?
    end
    redirect_to_current
  end




  def users
  end


  dyta(:users, :conditions=>{:company_id=>['@current_company.id'],:deleted=>false}) do |t| 
    t.column :name
    t.column :first_name
    t.column :last_name
    t.column :name, :through=>:role, :label=>tc(:role), :url=>{:action=>:roles_update}
    # t.column :free_price
    # t.column :credits
    # t.column :reduction_percent
    t.column :email
    t.column :admin
    t.action :locked, :actions=>{"true"=>{:action=>:users_unlock},"false"=>{:action=>:users_lock}}, :method=>:post, :if=>'RECORD.id!=@current_user.id'
    t.action :users_update 
    t.action :users_delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.id!=@current_user.id'
  end

  def users_create
    if request.xhr?
      role = find_and_check(:role, params[:user_role_id])
      @rights = role.rights_array if role
      render :partial=>"rights_form"
    else
      if request.post?
        @user = User.new(params[:user])
        @user.company_id = @current_company.id
        @user.rights_array = (params[:rights]||{}).keys
        @rights = @user.rights_array
        redirect_to_back if @user.save
      else
        role = @current_company.roles.first
        @user = User.new(:admin=>false, :role=>role)
        @rights = role ? role.rights_array : []
      end
    end
    render_form
  end

  def users_update
    @user = User.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post?
      @user.attributes = params[:user]
      @user.rights_array = (params[:rights]||{}).keys
      @rights = @user.rights_array
      redirect_to_back if @user.save
    else
      @rights = @user.rights_array
    end
    render_form
  end
  
  def users_delete
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





  dyta(:sequences, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :compute
    t.column :format, :class=>:code
    t.column :period_name
    t.action :sequences_update
    t.action :sequences_delete, :method=>:post, :confirm=>:are_you_sure, :if=>"RECORD.destroyable\?"
  end

  def sequences
  end

  def sequences_create
    if request.post? 
      @sequence = Sequence.new(params[:sequence])
      @sequence.company_id = @current_company.id
      redirect_to_back if @sequence.save
    else
      @sequence = Sequence.new :format=>'[number|8]', :last_number=>0
    end
    render_form
  end

  def sequences_update
    @sequence = Sequence.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @sequence
      if @sequence.update_attributes(params[:sequence])
        redirect_to_back
      end
    end
    @title = {:value=>@sequence.name}
    render_form
  end

  def sequences_delete
    if request.post? or request.delete?
      @sequence = Sequence.find_by_id_and_company_id(params[:id], @current_company.id)
      Sequence.destroy(@sequence.id) if @sequence and @sequence.destroyable?
    end
    redirect_to_current
  end









  dyta(:listings, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :root_model_name
    t.column :comment
    t.action :listings, :format=>'csv'
    t.action :listing_nodes, :image=>:spread
    t.action :listings_update
    t.action :listings_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def listings
  end

  def listings_build
    flash[:warning] = 'En construction'
    redirect_to_back
  end
  
  def listings_create
    if request.post?
      @listing = Listing.new(params[:listing])
      @listing.company_id = @current_company.id
      redirect_to_back if @listing.save
    else
      @listing = Listing.new
    end
    render_form
  end
  
  def listings_update
    @listing = find_and_check(:listing, params[:id])
    if request.post? and @listing
      if @listing.update_attributes(params[:listing])
        redirect_to_back
      end
    end
    @title ={:value=>@listing.name}
    render_form
  end

  def listings_delete
    if request.post? or request.delete?
      @listing = find_and_check(:listing, params[:id])
      Listing.destroy(@listing.id) if @listing
    end
    redirect_to_back
  end


  dyta(:listing_nodes, :conditions=>{:company_id=>['@current_company.id'], :listing_id=>['session[:current_listing_id]']}) do |t|
    t.column :name
    t.column :label
    t.action :listings_update
    t.action :listings_delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  def listing_nodes
    @listing = find_and_check(:listing, params[:id])
    if @listing
      session[:current_listing_id] = @listing.id
    end
  end

  def listing_nodes_create
    if request.post?
      @listing_node = ListingNode.new(params[:listing_node])
      @listing_node.company_id = @current_company.id
      @listing_node.listing_id = session[:current_listing_id]
      redirect_to_back if @listing_node.save
    else
      @listing_node = ListingNode.new
    end
    render_form
  end
  
  def listing_nodes_update
    @listing_node = find_and_check(:listing_node, params[:id])
    if request.post? and @listing_node
      if @listing_node.update_attributes(params[:listing_node])
        redirect_to_back
      end
    end
    @title ={:value=>@listing_node.name}
    render_form
  end

  def listing_nodes_delete
    if request.post? or request.delete?
      @listing_node = find_and_check(:listing_node, params[:id])
      ListingNode.destroy(@listing_node.id) if @listing_node
    end
    redirect_to_back
  end




end
