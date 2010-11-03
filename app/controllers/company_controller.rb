# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require "rexml/document"
require "zlib"

class CompanyController < ApplicationController
  include ApplicationHelper

  @@helps = {}
  for file in Dir["#{Rails.root.to_s}/config/locales/#{I18n.locale}/help/*.txt"].sort
    File.open(file, 'rb') do |f| 
      @@helps[file] = {:title=>f.read[/^======\s*(.*)\s*======$/, 1], :name=>file.split(/[\\\/\.]+/)[-2]}
      raise Exception.new("No good title for #{file}") if @@helps[file][:title].blank?
    end
  end

  def index
    t3e :user=>@current_user.label, :company=>@current_company.name
  end


  def tabbox_index
    session[:tabbox] ||= {}
    session[:tabbox][params['id']] = params['index']
    render :text=>nil
  end


  def formalize
    @options = {}
    for x in [:reflection, :order, :label, :include_blank]
      @options[x] = params[x]
    end
    render :inline=>'<%=options_for_select(@current_company.reflection_options(@options), params[:selected].to_i)-%>'
  end


  def welcome
    index
    render :action=>:index
  end

  def unknown_action
    notify(:unknown_action, :error, :url=>request.url.inspect)
    redirect_to :action=>:index
  end
  

  def side
    preference = @current_user.preference("interface.side.#{params[:id]}.opened", true, :boolean)
    preference.set !preference.value
    preference.save!
    render :text=>''
  end


  def about
    @properties = []
#     begin
#       @properties = Rails::Info.properties.dup
#     rescue
#       @properties = []
#     end
#     @properties.reverse!
    @properties.insert(0, ["Ekylibre version", Ekylibre.version])
    @properties << ["Database version", ActiveRecord::Migrator.current_version]
  end

  def help
    @per_page = 10
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
    @my_company = @current_company
    # Default treatment
    @tree = Preference.tree_reference.sort
    for k, v in @tree
      for name, options in v
        param = @my_company.preference(name)
        if param
          options[:value] = param.value 
          options[:value] = options[:value].id if param.record? and options[:value]
        end
        options[:value] = options[:default] if options[:value].nil?
      end
    end
    if request.post?
      saved = false
      ActiveRecord::Base.transaction do
        saved = @my_company.update_attributes(params[:my_company])
        if saved
          for key, data in params[:preference]
            preference = @my_company.preferences.find_by_name(key)
            preference = @my_company.preferences.build(:name=>key) if preference.nil?
            preference.value = data[:value]
            unless preference.save
              saved = false
              @my_company.errors.add_from_record(preference)
              raise ActiveRecord::Rollback
            end
          end
        end
      end
      redirect_to_back if saved
    end
    t3e @my_company.attributes
  end



  def backups

    if request.post?
      if params['backup']
        # Création d'une sauvegarde
        backup = @current_company.backup(:creator=>@current_user.label, :with_prints=>params[:with_prints])
        send_file(backup, :stream=>false)
        File.delete(backup)
      elsif params['restore'] and params[:file] and params[:file][:path]
        # Récupération d'une sauvegarde
        backup = params[:file][:path]
        file = Rails.root.join("tmp", "uploads", backup.original_filename+"."+rand.to_s[2..-1].to_i.to_s(36))
        File.open(file, "wb") { |f| f.write(backup.read)}
        start = Time.now
        if @current_company.restore(file)
          @current_company.reload
          notify(:restoration_finished, :success, :now, :value=>(Time.now-start).to_s, :code=>@current_company.code)
        else
          notify(:unvalid_version_for_restore, :error, :now)
        end
      end
    end

  end


  create_kame(:establishments, :conditions=>{:company_id=>['@current_company.id']}, :order=>:nic) do |t|
    t.column :name
    t.column :nic
    t.column :siret
    t.column :comment
    t.action :establishment_update
    t.action :establishment_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def establishments
  end

  manage :establishments


  create_kame(:departments, :conditions=>{:company_id=>['@current_company.id']},:order=>:name) do |t| 
    t.column :name
    t.column :comment
    t.action :department_update
    t.action :department_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def departments
  end

  manage :departments

  create_kame(:roles, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name, :children=>:users) do |t| 
    t.column :name, :children=>:label
    t.column :diff_more, :class=>'rights more'
    t.column :diff_less, :class=>'rights less'
    t.action :role_update
    t.action :role_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def roles
  end

  def role_create
    @role = Role.new
    if request.post?
      @role = Role.new(params[:role])
      @role.company_id = @current_company.id
      @role.rights_array = (params[:rights]||{}).keys
      @rights = @role.rights_array
      return if save_and_redirect(@role)
    else
      @rights = User.rights_list      
    end
    render_form
  end

  def role_update
    return unless @role = find_and_check(:role)
    if request.post?
      @role.attributes = params[:role]
      @role.rights_array = (params[:rights]||{}).keys
      @rights = @role.rights_array
      return if save_and_redirect(@role)
    else
      @rights = @role.rights_array
    end
    t3e @role.attributes
    render_form
  end

  def role_delete
    return unless @role = find_and_check(:role)
    if request.post? or request.delete?
      Role.destroy(@role.id) if @role and @role.destroyable?
    end
    redirect_to_current
  end


  def change_password
    @user = @current_user
    if request.post?
      if @user.authenticated? params[:user][:old_password]
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.save
          notify(:password_successfully_changed, :success)
          redirect_to :action=>:index 
        end
        @user.password = @user.password_confirmation = ''
      else
        @user.errors.add(:old_password, :invalid) 
      end      
    end
  end

  def user_statistics
    session[:statistics_start] ||= Date.today << 12
    session[:statistics_end]   ||= Date.today
    @sales_orders_count = SalesOrder.count_by_sql ["SELECT  count(*) FROM #{SalesOrder.table_name} WHERE company_id = ? AND state != 'P' AND responsible_id = ? AND created_on BETWEEN ? AND ? ", @current_company.id, @current_user.id, session[:statistics_start], session[:statistics_end] ]
    @sales_orders_amount = SalesOrder.count_by_sql ["SELECT sum(amount) FROM #{SalesOrder.table_name} WHERE company_id = ? AND state != 'P' AND responsible_id = ? AND created_on BETWEEN ? AND ? ", @current_company.id, @current_user.id, session[:statistics_start], session[:statistics_end] ]
    @invoiced_amount = SalesInvoice.count_by_sql ["SELECT sum(sales_invoices.amount) FROM #{SalesInvoice.table_name} AS sales_invoices INNER JOIN #{SalesOrder.table_name} AS sales_orders ON sales_orders.responsible_id = ? AND sales_invoices.sales_order_id = sales_orders.id WHERE sales_invoices.company_id = ? AND sales_invoices.payment_on BETWEEN ? AND ? ", @current_user.id,  @current_company.id,session[:statistics_start], session[:statistics_end] ]
    @event_natures = EventNature.find_by_sql ["SELECT en.*, ecount, esum FROM #{EventNature.table_name} AS en LEFT JOIN (SELECT nature_id , count(id) as ecount, sum(duration) as esum FROM #{Event.table_name} WHERE started_at BETWEEN ? AND ? AND responsible_id = ? GROUP BY nature_id) as stats ON id = nature_id  WHERE company_id = ? ORDER BY name ", session[:statistics_start].to_date.beginning_of_day, session[:statistics_end].to_date.end_of_day, @current_user.id, @current_company.id]
    if request.post?
      session[:statistics_start] = params[:start].to_date
      session[:statistics_end] = params[:end].to_date
      redirect_to_current
    end
  end




  def users
  end

  create_kame(:users, :conditions=>{:company_id=>['@current_company.id']}, :order=>:last_name, :line_class=>"(RECORD.locked ? 'critic' : '')", :per_page=>20) do |t| 
    t.column :name, :url=>{:action=>:user}
    t.column :first_name, :url=>{:action=>:user}
    t.column :last_name, :url=>{:action=>:user}
    t.column :name, :through=>:role, :url=>{:action=>:role_update}
    # t.column :reduction_percent
    t.column :email
    t.column :admin
    t.column :employed
    t.action :locked, :actions=>{"true"=>{:action=>:user_unlock},"false"=>{:action=>:user_lock}}, :method=>:post, :if=>'RECORD.id!=@current_user.id'
    t.action :user_update 
    t.action :user_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.id!=@current_user.id'
  end

  def user
    return unless @user = find_and_check(:user)
    t3e @user.attributes
  end

  def user_create
    if request.xhr? and params[:mode] == "rights"
      role = @current_company.roles.find(params[:user_role_id]) rescue nil
      @rights = role.rights_array if role
      render :partial=>"rights_form"
    else
      if request.post?
        @user = User.new(params[:user])
        @user.company_id = @current_company.id
        @user.rights_array = (params[:rights]||{}).keys
        @rights = @user.rights_array        
        return if save_and_redirect(@user)
      else
        role = @current_company.roles.first
        @user = @current_company.users.new(:admin=>false, :role=>role, :employed=>params[:employed])
        @rights = role ? role.rights_array : []
      end
    end
    render_form
  end

  def user_update
    return unless @user = find_and_check(:user)
    if request.post?
      @user.attributes = params[:user]
      @user.rights_array = (params[:rights]||{}).keys
      @rights = @user.rights_array
      return if save_and_redirect(@user)
    else
      @rights = @user.rights_array
    end
    t3e @user.attributes
    render_form
  end
  
  def user_delete
    return unless @user = find_and_check(:user)
    if request.post? or request.delete? and @user.destroyable?
      @user.destroy
    end
    redirect_to_back
  end
  
  def user_lock
    return unless @user = find_and_check(:user)
    if @user
      @user.locked = true
      @user.save
    end
    redirect_to_current
  end
  
  def user_unlock
    return unless @user = find_and_check(:user)
    if @user
      @user.locked = false
      @user.save
    end
    redirect_to_current
  end

  create_kame(:document_templates, :conditions=>{:company_id=>['@current_company.id']}, :order=>"nature, name") do |t|
    t.column :active
    t.column :name
    t.column :code
    t.column :family_label
    t.column :nature_label
    t.column :by_default
    t.column :to_archive
    t.column :language
    t.column :country
    t.action :document_template_print
    t.action :document_template_duplicate, :method=>:post
    t.action :document_template_update
    t.action :document_template_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def document_templates
  end

  manage :document_templates, :country=>"@current_company.entity.country", :language=>"@current_company.entity.language"

  def document_templates_load
    @current_company.load_prints
    notify(:update_is_done, :success, :now)
    redirect_to :action=>:document_templates
  end

  def document_template_print
    return unless @document_template = find_and_check(:document_template)
    send_data @document_template.sample, :filename=>@document_template.name.simpleize, :type=>Mime::PDF, :disposition=>'inline'
  end

  def document_template_duplicate
    return unless @document_template = find_and_check(:document_template)
    if request.post?
      if @document_template 
        attrs = @document_template.attributes.dup
        attrs.delete("id")
        attrs.delete("lock_version")
        attrs.delete_if{|k,v| k.match(/...ate.._../) }
        while @current_company.document_templates.find(:first, :conditions=>{:code=>attrs["code"]})
          attrs["code"].succ!
        end
        DocumentTemplate.create(attrs)
      end
    end
    redirect_to_current    
  end





  create_kame(:sequences, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :compute
    t.column :format, :class=>:code
    t.column :period_name
    t.action :sequence_update
    t.action :sequence_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def sequences_load
    @current_company.load_sequences
    redirect_to_back
  end

  def sequences
  end

  manage :sequences, :format=>"'[number|8]'", :last_number=>"0"

  create_kame(:listings, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name, :url=>{:action=>:listing_update}
    t.column :root_model_name
    t.column :comment
    t.action :listing_extract, :url=>{:format=>:csv}, :image=>:action
    t.action :listing_extract, :url=>{:format=>:csv, :mode=>:no_mail}, :if=>'RECORD.mail_columns.size > 0', :image=>:nomail
    t.action :listing_mail, :if=>'RECORD.mail_columns.size > 0'
    t.action :listing_duplicate, :method=>:post
    t.action :listing_update
    t.action :listing_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def listings
    session[:listing_mail_column] = nil
  end

  def listing_extract
    return unless @listing = find_and_check(:listing)
    begin
      @listing.save if @listing.query.blank?
      query = @listing.query.to_s
      # FIXME: This is dirty code to solve quickly no_mail mode
      query.gsub!(" ORDER BY ", " AND ("+@listing.mail_columns.collect{|c| "#{c.name} NOT LIKE '%@%.%'" }.join(" AND ")+") ORDER BY ") if params[:mode] == "no_mail"
      query.gsub!(/CURRENT_COMPANY/i, @current_company.id.to_s)
      first_line = []
      @listing.exportable_columns.each {|line| first_line << line.label}
      result = ActiveRecord::Base.connection.select_rows(query)
      result.insert(0, first_line)
      csv_string = FasterCSV.generate do |csv|
        for line in result
          csv << line
        end
      end
      send_data(csv_string, :filename=>@listing.name.simpleize+'.csv', :type=>Mime::CSV)
    rescue Exception=>e
      notify(:fails_to_extract_listing, :error, :message=>e.message)
      redirect_to_current
    end
  end
  
  def listing_mail
    return unless @listing = find_and_check(:listing)
    if @listing.mail_columns.size == 0
      notify(:you_must_have_an_email_column, :warning)
      redirect_to_back
      return
    end
    if session[:listing_mail_column] or @listing.mail_columns.size ==  1
      if (query = @listing.query).blank?
        @listing.save 
        query = @listing.query
      end
      query = query.to_s
      query.gsub!(/CURRENT_COMPANY/i, @current_company.id.to_s)
      full_results = ActiveRecord::Base.connection.select_all(query)
      listing_mail_column = @listing.mail_columns.size == 1 ? @listing.mail_columns[0] : find_and_check(:listing_nodes, session[:listing_mail_column])
      #raise Exception.new listing_mail_column.inspect
      results = full_results.select{|c| !c[listing_mail_column.label].blank? }
      @mails = results.collect{|c| c[listing_mail_column.label] }
      # @mails.uniq! ### CHECK ????????
      @columns = (full_results.size > 0 ? full_results[0].keys.sort : [])
      session[:mail] ||= {}
    end
    if request.post?
      if params[:node]
        session[:listing_mail_column] = ListingNode.find_by_company_id_and_key(@current_company.id, params[:node][:mail]).id
        redirect_to_current
      else
        session[:mail] = params.dup
        session[:mail].delete(:attachment)
        texts = [params[:mail_subject], params[:mail_body]]
        attachment = params[:attachment]
        if attachment
          # file = "#{Rails.root.to_s}/tmp/uploads/attachment_#{attachment.original_filename.gsub(/\W/,'_')}"
          # File.open(file, "wb") { |f| f.write(attachment.read)}
          attachment = {:filename=>attachment.original_filename, :content_type=>attachment.content_type, :body=>attachment.read.dup}
        end
        if params[:send_test]
          results = [results[0]]
          results[0][listing_mail_column.label] = params[:from]
        end
        for result in results
          ts = texts.collect do |t|
            r = t.to_s.dup
            @columns.each{|c| r.gsub!(/\{\{#{c}\}\}/, result[c].to_s)}
            r
          end
          Mailman.deliver_message(params[:from], result[listing_mail_column.label], ts[0], ts[1], attachment)
          notify(:mails_are_sent, :success, :now)
        end
        nature = @current_company.event_natures.find(:first, :conditions=>{:usage=>"mailing"}).nil? ? @current_company.event_natures.create!(:name=>tc(:mailing), :duration=>5, :usage=>"mailing").id : @current_company.event_natures.find(:first, :conditions=>{:usage=>"mailing"})
        #raise Exception.new nature.inspect
        for contact in @current_company.contacts.find(:all, :conditions=>["email IN (?) AND active = ? ", @mails, true])
          @current_company.events.create!(:entity_id=>contact.entity_id, :started_at=>Time.now, :duration=>5, :nature_id=>nature.id, :user_id=>@current_user.id)
        end
        session[:listing_mail_column] = nil
      end
    end
    t3e :listing => @listing.name
  end

  def listing_create
    if request.post?
      @listing = Listing.new(params[:listing])
      @listing.company_id = @current_company.id
      return if save_and_redirect(@listing, :url=>{:action=>:listing_update, :id=>"id"})
    else
      @listing = Listing.new
    end
    render_form
  end
  
  def listing_update
    return unless @listing = find_and_check(:listing)
    if request.post? and @listing
      @listing.attributes = params[:listing]
      return if save_and_redirect(@listing, :url=>{:action=>:listing_update, :id=>"id"})
    end
    t3e @listing.attributes
    # render_form
  end

  def listing_duplicate
    return unless @listing = find_and_check(:listing)
    @listing.duplicate if request.post?
    redirect_to :action=>:listings
  end

  def listing_delete
    return unless @listing = find_and_check(:listing)
    if request.post? or request.delete?
      Listing.destroy(@listing.id) if @listing
    end
    redirect_to :action=>:listings
  end


#   def listing_node
#     return unless @listing_node = find_and_check(:listing_node)
#     render :partial=>"listing_node"
#   end


  def listing_node_create
    return unless @listing_node = find_and_check(:listing_node, params[:parent_id])
    render :text=>"[UnfoundListingNode]" unless @listing_node
    desc = params[:nature].split("-")
    # raise Exception.new desc.inspect
    if desc[0] == "special"
      if desc[1] == "all_columns"
        model = @listing_node.model
        for column in model.content_columns.sort{|a,b| model.human_attribute_name(a.name.to_s)<=>model.human_attribute_name(b.name.to_s)}
          ln = @listing_node.children.new(:nature=>"column", :attribute_name=>column.name, :label=>@listing_node.model.human_attribute_name(column.name))
          ln.save!
        end
      end
    else
      ln = @listing_node.children.new(:nature=>desc[0], :attribute_name=>desc[1], :label=>@listing_node.model.human_attribute_name(desc[1]))
      ln.save!
    end
    
    render(:partial=>"listing_reflection", :object=>@listing_node)
  end
  
  def listing_node_update
    return unless @listing_node = find_and_check(:listing_node)
    if request.xhr?
      if params[:type] == "hide" or params[:type] == "show"
        @listing_node.exportable = !@listing_node.exportable
        render :text=>""
      elsif params[:type] == "column_label"
        @listing_node.label = params[:label]
        render(:partial=>"listing_node_column_label", :object=>@listing_node)
      elsif params[:type] == "comparison"
        @listing_node.condition_operator = params[:comparator]
        @listing_node.condition_value = params[:comparison_value]
        render(:partial=>"listing_node_comparison", :object=>@listing_node)
      elsif params[:type] == "position"
        @listing_node.position = params[:position]
        render(:partial=>"listing_node_position", :object=>@listing_node)
      end
      @listing_node.save
    else
      redirect_to :action=>:listings
    end
  end

  def listing_node_delete
    return unless @listing_node = find_and_check(:listing_node)
    parent = nil
    if request.post?
      parent = @listing_node.parent
      @listing_node.destroy 
    end
    if request.xhr?
      render(:partial=>"listing_reflection", :object=>parent)
    end
  end
  
  def print
    headers["Cache-Control"] = 'maxage=3600'  
    headers["Pragma"] = 'public'  
    begin
      data, filename = @current_company.print(params)
      send_data(data, :filename=>filename, :type=>Mime::PDF, :disposition=>'inline')
    rescue Exception=>e
      notify(:print_failure, :error, :class=>e.class.to_s, :error=>e.message.to_s)
      # (Rails.env=="development" ? e.inspect+e.backtrace.join("\n") :
      redirect_to_back
    end
  end
  

  create_kame(:units, :conditions=>{:company_id=>["@current_company.id"]}, :order=>:name) do |t|
    t.column :label
    t.column :name
    t.column :coefficient
    t.column :base
    t.column :start
    t.action :unit_update
    t.action :unit_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def units
  end

  def units_load
    @current_company.load_units
    redirect_to :action=>:units
  end

  manage :units, :base=>"params[:base]"


  def import
    @supported_files = [["EBP.EDI", :ebp_edi]]
    if request.post?
      data = params[:upload]
      file = "#{Rails.root.to_s}/tmp/uploads/#{data.original_filename}.#{rand.to_s[2..-1].to_i.to_s(36)}"
      File.open(file, "wb") {|f| f.write(data.read)}
      if params[:nature] == "ebp_edi"
        File.open(file, "rb") do |f|
          unless f.readline.match(/^EBP\.EDI$/)
            notify(:bad_file, :error, :now)
            return
          end
          encoding = f.readline
          f.readline
          owner = f.readline
          started_on = f.readline
          started_on = Date.civil(started_on[4..7].to_i, started_on[2..3].to_i, started_on[0..1].to_i)          
          stopped_on = f.readline
          stopped_on = Date.civil(stopped_on[4..7].to_i, stopped_on[2..3].to_i, stopped_on[0..1].to_i)          
          ic = Iconv.new("utf-8", "cp1252")
          begin
            ActiveRecord::Base.transaction do
              while 1
                begin
                  line = f.readline.gsub(/\n/, '')
                rescue
                  break
                end
                unless @current_company.financial_years.find_by_started_on_and_stopped_on(started_on, stopped_on)
                  @current_company.financial_years.create!(:started_on=>started_on, :stopped_on=>stopped_on)
                end
                line = ic.iconv(line).split(/\;/)
                if line[0] == "C"
                  unless @current_company.accounts.find_by_number(line[1])
                    @current_company.accounts.create!(:number=>line[1], :name=>line[2])
                  end
                elsif line[0] == "E"
                  unless journal = @current_company.journals.find_by_code(line[3])
                    journal = @current_company.journals.create!(:code=>line[3], :name=>line[3], :nature=>Journal.natures[-1][1].to_s, :closed_on=>started_on-1)
                  end
                  number = line[4].blank? ? "000000" : line[4]
                  line[2] = Date.civil(line[2][4..7].to_i, line[2][2..3].to_i, line[2][0..1].to_i)
                  unless entry = journal.entries.find_by_number_and_printed_on(number, line[2])
                    entry = journal.entries.create!(:number=>number, :printed_on=>line[2])
                  end
                  unless account = @current_company.accounts.find_by_number(line[1])
                    account = @current_company.accounts.create!(:number=>line[1], :name=>line[1])
                  end
                  line[8] = line[8].strip.to_f
                  if line[7] == "D"
                    entry.add_debit(line[6], account, line[8], :letter=>line[10])
                  else
                    entry.add_credit(line[6], account, line[8], :letter=>line[10])
                  end
                end
              end
            end
            notify(:importation_finished, :success, :now)
          rescue Exception => e
            notify(:importation_cancelled, :error, :now)
          end
        end
      else
        notify(:invalid_file_nature, :error, :now)
      end
    end
    
  end


end
