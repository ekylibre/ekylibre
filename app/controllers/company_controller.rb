require "rexml/document"
require "zlib"

class CompanyController < ApplicationController

  helps = Dir["#{RAILS_ROOT}/config/locales/#{I18n.locale}/help/*.txt"].sort
  @@helps = {}
  for file in helps
    File.open(file, 'rb') do |f| 
      data = f.read
      @@helps[file] = {:title=>data[/^h1.\s*(.*)\s*$/, 1], :name=>file.split(/(\\|\/|\.)/)[-3]}
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

  def general
    @company = @current_company
    @title = {:name=>@company.name, :code=>@company.code}
  end

  def help
    @per_page = 20
    if request.post?
      @key = params[:key]
      @key_words = @key.lower.split(" ").select{|x| x.strip.length>2}
      reg = /(#{@key_words.join("|")})/i
      @results = []
      for file in @@helps.keys
        File.open(file) do |f| 
          data = f.read
          if (match = data.scan(reg).size) > 0
            @results << @@helps[file].merge(:count=>match) 
          end
        end
      end
      @results.sort!{|a,b| b[:count]<=>a[:count]}
      max = @results[0][:count]
      @results.each{|r| r[:pertinence] = (100*r[:count]/max).to_i}
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
    company = @current_company
    version = (ActiveRecord::Migrator.current_version rescue 0)
    filename = "backup-"+@current_company.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")
    file = "#{RAILS_ROOT}/tmp/#{filename}.xml.gz"
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new
    backup = doc.add_element 'backup', 'version'=>version, 'creation-date'=>Date.today.to_s, 'creator'=>@current_user.label
    root = backup.add_element 'company', company.attributes
    n = 0
    start = Time.now.to_i
    reflections = Company.reflections
    for name in reflections.keys.collect{|x| x.to_s}.sort
      reflection = reflections[name.to_sym]
      if reflection.macro==:has_many
        rows = company.send(name.to_sym).find(:all, :order=>:id)
        rows_count = rows.size
        n += rows_count
        table = root.add_element('rows', 'reflection'=>name, 'records-count'=>rows_count.to_s)
        rows_count.times do |i|
          puts i if i%200==0
          table.add_element('row', rows[i].attributes)
        end
      end
    end
    backup.add_attributes('records-count'=>n.to_s, 'generation-duration'=>(Time.now.to_i-start).to_s)
    stream = doc.to_s
    Zlib::GzipWriter.open(file) { |gz| gz.write(stream) }
    send_file file
  end

  def restore
    if request.post?
      company = @current_company
      # Récupération du fichier
      backup = params[:backup][:path]
      file = "#{RAILS_ROOT}/tmp/uploads/#{backup.original_filename}.#{rand.to_s[2..-1].to_i.to_s(36)}"
      File.open(file, "w") { |f| f.write(backup.read)}
      # Décompression
      stream = nil
      Zlib::GzipReader.open(file) { |gz| stream = gz.read }
      doc = REXML::Document.new(stream)
      backup = doc.root

      version = (ActiveRecord::Migrator.current_version rescue 0)
      if backup.attribute('version').value != version.to_s
        flash.now[:error] = tc :unvalid_version_for_restore
        return
      end

      root = backup.elements[1]

      ActiveRecord::Base.transaction do
        start = Time.now.to_i
        # Suppression des données
        ids  = {}
        keys = {}
        reflections = Company.reflections
        for name in reflections.keys.collect{|x| x.to_s}.sort
          reflection = reflections[name.to_sym]
          if reflection.macro==:has_many
            other = reflection.class_name
            other_class = other.constantize
            ids[other] = {}
            keys[other] = {}
            for name, ref in other_class.reflections
              # Ex. : keys["User"]["role_id"] = "Role"
              keys[other][ref.primary_key_name] = (ref.options[:polymorphic] ? ref.options[:foreign_type].to_sym : ref.class_name) if ref.macro==:belongs_to and ref.class_name!=Company.name
            end
            other_class.delete_all(:company_id=>company.id)
          elsif reflection.macro==:belongs_to
            keys[Company.name] ||= {}
            keys[Company.name][reflection.primary_key_name] = reflection.class_name
          end
        end


        # Chargement des données sauvegardées
        data = []
        for table in root.elements
          reflection = Company.reflections[table.attributes['reflection'].to_sym]
          puts('>> '+reflection.name.to_s)
          for r in table.elements
            attributes = r.attributes
            id = attributes['id']
            attributes.delete('id')
            attributes.delete('company_id')
            record = company.send(reflection.name).build
            attributes.each{|k,v| record.send(k+'=', v)}
            # record.save(false)
            record.send(:create_without_callbacks)
            ids[reflection.class_name][id] = record.id
            data << record
          end
        end


        # Réorganisation des clés étrangères
        for record in data
          for key, class_name in keys[record.class.name]
            # user[:role_id] = ids["Role"][user[:role_id].to_s]
            #raise Exception.new('>> '+class_name.inspect) if ids[class_name].nil?
            if class_name.is_a? Symbol
              v = ids[record[class_name]][record[key].to_s]
            else
              v = ids[class_name][record[key].to_s]
            end
            record[key] = v unless v.nil? # ||record[key]
          end
          # record.save(false)
          record.send(:update_without_callbacks)
        end


        # Chargement des paramètres de la société
        old_code = company.code
        attrs = root.attributes
        attrs.delete('id')
        attrs.delete('lock_version')
        attrs.each{|k,v| company.send(k+'=', v)}
        for key, class_name in keys[Company.name]
          v = ids[class_name][company[key].to_s]
          company[key] = v unless v.nil?
        end
        # company.save! #send(:update_without_callbacks) # 
        company.send(:update_without_callbacks)
        @new_code = company.code if old_code!=company.code

        # raise Exception.new('Pas tout de suite')
        flash.now[:notice] = tc(:restoration_finished, :value=>(Time.now.to_i-start).to_s)
      end

    end
  end
  






  dyta(:establishments, :conditions=>{:company_id=>['@current_company.id']}, :empty=>true) do |t|
    t.column :name
    t.column :nic
    t.column :siret
    t.column :comment
    t.action :establishments_update, :image=>:update
    t.action :establishments_delete, :image=>:delete , :method=>:post , :confirm=>:are_you_sure
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
      Establishment.delete(params[:id]) if @establishment
    end
    redirect_to_back
  end



  dyta(:departments, :conditions=>{:company_id=>['@current_company.id']}, :empty=>true) do |t| 
    t.column :name
    t.column :comment
    t.action :departments_update, :image=>:update
    t.action :departments_delete, :image=>:delete , :method=>:post , :confirm=>:are_you_sure
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
    @department = Department.find_by_id_and_company_id(params[:id] , @current_company.id)
    if request.post? and @department
      if @department.update_attributes(params[:department])
        redirect_to_back
      end
    end
    render_form
  end

  def departments_delete
    if request.post? or request.delete?
      @department= Department.find_by_id_and_company_id(params[:id] , @current_company.id)
      Department.delete(params[:id]) if @department
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
      @role = Role.find_by_id_and_company_id(params[:id] , @current_company.id)
      Role.delete(@role.id) if @role and @role.destroyable?
    end
    redirect_to_current
  end




  def users
  end


  dyta(:users, :conditions=>{:company_id=>['@current_company.id'],:deleted=>false}, :empty=>true) do |t| 
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
    t.action :users_update, :image=>:update 
    t.action :users_delete, :image=>:delete , :method=>:post , :confirm=>:are_you_sure, :if=>'RECORD.id!=@current_user.id'
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
    t.action :sequences_delete, :method=>:post , :confirm=>:are_you_sure, :if=>"RECORD.destroyable\?"
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
    @sequence = Sequence.find_by_id_and_company_id(params[:id] , @current_company.id)
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
      @sequence = Sequence.find_by_id_and_company_id(params[:id] , @current_company.id)
      Sequence.delete(@sequence.id) if @sequence and @sequence.destroyable?
    end
    redirect_to_current
  end




  def listings
    @klass = Entity

    @reflections = @klass.reflections.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
    
    
  end



  
end
