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

class RelationsController < ApplicationController

  dyli :clients_accounts, [:number, :name], :model=>:accounts, :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_clients_accounts.to_s+'%'"]]
  dyli :suppliers_accounts, [:number, :name], :model=>:accounts, :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_suppliers_accounts.to_s+'%'"]]
  dyli :attorneys_accounts, [:number, :name], :model=>:accounts, :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_attorneys_accounts.to_s+'%'"]]


  create_kame(:user_future_events, :model=>:events, :conditions=>['company_id = ? AND started_at >= CURRENT_TIMESTAMP', ['@current_company.id']], :order=>"started_at ASC", :line_class=>"(RECORD.responsible_id=@current_user.id ? 'notice' : '')", :per_page=>10) do |t|
    t.column :started_at
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity}
    t.column :name, :through=>:nature
    t.column :duration
    t.column :location
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
  end 

  create_kame(:recent_events, :model=>:events, :conditions=>['company_id = ? AND started_at < CURRENT_TIMESTAMP',['@current_company.id']], :order=>"started_at DESC", :per_page=>10) do |t|
    t.column :started_at
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity}
    t.column :name, :through=>:nature
    t.column :duration
    t.column :location
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
  end

  #
  def index
    @entities = @current_company.entities
  end

  #
  def auto_complete_for_contact_line_6
    if params[:contact] and request.xhr?
      pattern = '%'+params[:contact][:line_6].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @areas = @current_company.areas.find(:all, :conditions => [ 'LOWER(name) LIKE ? ', pattern], :order => "name ASC", :limit=>12)
      render :inline => "<%=content_tag(:ul, @areas.map { |area| content_tag(:li, h(area.name)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  def auto_complete_for_entity_origin
    if params[:entity] and request.xhr?
      pattern = '%'+params[:entity][:origin].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @entities = @current_company.entities.find(:all, :conditions=> [ 'LOWER(origin) LIKE ?', pattern ], :order=>"origin ASC", :limit=>12)
      render :inline => "<%=content_tag(:ul, @entities.map { |entity| content_tag(:li, h(entity.origin)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end

  def auto_complete_for_event_location
    if params[:event] and request.xhr?
      pattern = '%'+params[:event][:location].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @events = @current_company.events.find(:all, :conditions=> [ 'LOWER(location) LIKE ?', pattern ], :order=>"location ASC", :limit=>12)
      render :inline => "<%=content_tag(:ul, @events.map { |event| content_tag(:li, h(event.location)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end

  def auto_complete_for_mandate
    if params[:columns] and request.xhr?
      column = params[:column]||'family'
      pattern = '%'+params[:columns][column][:search].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ "LOWER(#{column}) LIKE ? ", pattern], :order=>column, :select => "DISTINCT #{column}")
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.#{column})) }.join.html_safe)-%>"
    else
      render :text=>'', :layout=>true
    end
  end

  def auto_complete_for_mandate_family
    if params[:mandate] and request.xhr?
      pattern = '%'+params[:mandate][:family].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(family) LIKE ? ', pattern], :order => "family ASC", :select => 'DISTINCT family')
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.family)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  def auto_complete_for_mandate_organization
    if params[:mandate] and request.xhr?
      pattern = '%'+params[:mandate][:organization].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(organization) LIKE ? ', pattern], :order => "organization ASC", :select => 'DISTINCT organization')
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.organization)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  #
  def auto_complete_for_mandate_title
    if params[:mandate] and request.xhr?
      pattern = '%'+params[:mandate][:title].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(title) LIKE ? ', pattern], :order => "title ASC", :select => 'DISTINCT title')
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.title)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  #
  create_kame(:areas, :conditions=>search_conditions(:areas, :areas=>[:postcode, :name]), :order=>:name) do |t| 
    t.column :name
    t.column :postcode
    t.column :city
    t.column :code
    t.column :name, :through=>:district
    t.column :country    
    t.action :area_update
    t.action :area_delete, :confirm=>:are_you_sure_you_want_to_delete, :method=>:delete
  end


  #this method lists all the areas.
  def areas
    session[:area_key] ||= {}
    @key = params[:key] || session[:area_key] 
    @areas = @current_company.areas
    if request.post?
      session[:area_key] = @key
    end
  end

  manage :areas, :district_id=>"@current_company.districts.find(params[:district_id]).id rescue 0", :country=>"@current_company.entity.country"

  create_kame(:districts, :children=>:areas, :conditions=>search_conditions(:districts, :districts=>[:code, :name]), :order=>:name) do |t| 
    t.column :name
    t.column :code
    t.action :area_create, :url=>{:district_id=>"(RECORD.id)", :id=>'nil'}
    t.action :district_update
    t.action :district_delete, :confirm=>:are_you_sure_you_want_to_delete, :method=>:delete
  end

  dyli(:districts, [:name, :code], :conditions=>{:company_id=>['@current_company.id']})
  
  ##
  def districts
    session[:district_key] ||= {}
    @districts_count = @current_company.districts.count
    @key = params[:key] || session[:district_key] 
    @districts = @current_company.districts
    if request.post?
      session[:district_key] = @key
    end
  end

  manage :districts


  create_kame(:custom_fields, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name
    t.column :nature_label
    t.column :required
    t.column :active
    t.column :choices_count, :datatype=>:integer
    t.action :custom_field_update
    t.action :custom_field, :image=>:menulist, :if=>'RECORD.nature == "choice"'
  end


  def custom_fields
  end

  def custom_field_create
    if request.post?
      @custom_field = CustomField.new(params[:custom_field])
      @custom_field.company_id = @current_company.id
      @custom_field.save # Permits to get ID if saved
      return if save_and_redirect(@custom_field, :url=>(@custom_field.nature=='choice' ? {:action=>:custom_field , :id=>@custom_field.id} : :back))
    else
      @custom_field = CustomField.new
    end
    render_form
  end
  
  def custom_field_update
    return unless @custom_field = find_and_check(:custom_field)
    if request.post?
      @custom_field.attributes = params[:custom_field]
      return if save_and_redirect(@custom_field)
    end
    t3e @custom_field.attributes
    render_form
  end


  create_kame(:custom_field_choices, :conditions=>{:company_id=>['@current_company.id'], :custom_field_id=>['session[:current_custom_field_id]']}, :order=>'position') do |t| 
    t.column :name 
    t.column :value
    t.action :custom_field_choice_up, :if=>"not RECORD.first\?", :method=>:post
    t.action :custom_field_choice_down, :if=>"not RECORD.last\?", :method=>:post
    t.action :custom_field_choice_update
  end
  

  def custom_field
    return unless @custom_field = find_and_check(:custom_field)
    session[:current_custom_field_id] = @custom_field.id
    t3e @custom_field.attributes
  end

  def custom_field_choice_create
    custom_field  = @current_company.custom_fields.find_by_id(params[:id])
    if request.post?
      @custom_field_choice = CustomFieldChoice.new(params[:custom_field_choice])
      @custom_field_choice.company_id = @current_company.id
      # @custom_field_choice.custom_field_id = @custom_field.id
      return if save_and_redirect(@custom_field_choice)
    else
      @custom_field_choice = CustomFieldChoice.new(:custom_field_id=>params[:custom_field_id])
    end
    render_form
  end

  def custom_field_choice_update
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.attributes = params[:custom_field_choice]
      return if save_and_redirect(@custom_field_choice)
    end
    @custom_field = @custom_field_choice.custom_field
    t3e @custom_field_choice.attributes
    render_form
  end
  
  
  def custom_field_sort
    return unless @custom_field = find_and_check(:custom_field)
    if request.post? and @custom_field
      @custom_field.sort_choices
    end
    redirect_to_current
  end

  # manage_list :custom_fields, :name

  def custom_field_choice_up
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.move_higher
    end
    redirect_to_current
  end
  
  def custom_field_choice_down
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.move_lower
    end
    redirect_to_current
  end
   
  create_kame(:entities, :conditions=>search_conditions(:entities, :entities=>[:code, :full_name, :website], :c=>[:address, :phone, :fax, :mobile, :email, :website]), :joins=>"LEFT JOIN #{Contact.table_name} AS c ON (entities.id=c.entity_id AND c.deleted_at IS NULL)", :order=>"entities.code") do |t|
    t.column :active, :datatype=>:boolean
    t.column :code, :url=>{:action=>:entity}
    t.column :title, :through=>:nature
    t.column :last_name, :url=>{:action=>:entity}
    t.column :first_name, :url=>{:action=>:entity}
    t.column :line_6, :through=>:default_contact, :url=>{:action=>:contact_update}
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:entity}
    t.action :entity_update
    t.action :entity_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end



  dyli(:entities, [:code, :full_name], :conditions => {:company_id=>['@current_company.id']})

  #
  def entities
    session[:entity_key] = params[:key]||session[:entity_key]
  end


  # create_kame(:entity_contacts, :model=>:contacts, :conditions=>['company_id = ? AND active = true AND (entity_id = ?  OR  entity_id IN ( SELECT entity_1_id FROM #{EntityLink.table_name}  INNER JOIN #{EntityLinkNature.table_name} ON #{EntityLink.table_name}.company_id = #{EntityLinkNature.table_name}.company_id WHERE #{EntityLink.table_name}.company_id = ? AND entity_1_id = ? OR entity_2_id = ?   AND #{EntityLinkNature.table_name}.propagate_contacts = true) OR entity_id IN  ( SELECT entity_2_id FROM #{EntityLink.table_name}  INNER JOIN #{EntityLinkNature.table_name} ON #{EntityLink.table_name}.company_id = #{EntityLinkNature.table_name}.company_id WHERE #{EntityLink.table_name}.company_id = ? AND entity_1_id = ? OR entity_2_id = ?   AND #{EntityLinkNature.table_name}.propagate_contacts = true) )', ['@current_company.id'], ['session[:current_entity_id]'], ['@current_company.id'] ,['session[:current_entity_id]'],['session[:current_entity_id]'], ['@current_company.id'] ,['session[:current_entity_id]'],['session[:current_entity_id]'] ]) do |t|
  # create_kame(:entity_contacts, :model=>:contacts, :conditions=>{:entity_id=>['session[:current_entity_id]']}) do |t|
  create_kame(:entity_contacts, :model=>:contacts, :conditions=>['#{Contact.table_name}.company_id = ? AND deleted_at IS NULL AND (entity_id = ? OR entity_id IN ( SELECT entity_1_id FROM #{EntityLink.table_name} INNER JOIN #{EntityLinkNature.table_name} ON (#{EntityLinkNature.table_name}.propagate_contacts = ? AND #{EntityLink.table_name}.nature_id = #{EntityLinkNature.table_name}.id AND stopped_on IS NULL) WHERE (entity_1_id = ? OR entity_2_id = ?)) OR entity_id IN (SELECT entity_2_id FROM #{EntityLink.table_name} INNER JOIN #{EntityLinkNature.table_name} ON #{EntityLinkNature.table_name}.propagate_contacts = ? AND #{EntityLink.table_name}.nature_id = #{EntityLinkNature.table_name}.id  AND stopped_on IS NULL WHERE (entity_1_id = ? OR entity_2_id = ?)))', ['@current_company.id'], ['session[:current_entity_id]'], true, ['session[:current_entity_id]'], ['session[:current_entity_id]'], true, ['session[:current_entity_id]'], ['session[:current_entity_id]'] ]) do |t|
    t.column :address, :url=>{:action=>:contact_update}
    t.column :phone
    t.column :fax
    t.column :mobile
    t.column :email
    t.column :website
    t.column :by_default
    t.column :code, :through=>:entity, :url=>{:action=>:entity}
    t.action :contact_update  
    t.action :contact_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  create_kame(:entity_subscriptions, :conditions=>{:company_id => ['@current_company.id'], :entity_id=>['session[:current_entity_id]']}, :model=>:subscriptions, :order=>'stopped_on DESC, first_number DESC', :line_class=>"(RECORD.active? ? 'enough' : '')") do |t|
    t.column :number
    t.column :name, :through=>:nature
    t.column :start
    t.column :finish
    t.column :number, :through=>:sale, :url=>{:action=>:sale, :controller=>:management}
    t.column :address, :through=>:contact
    t.column :quantity, :datatype=>:decimal
    t.column :suspended
    t.action :subscription_update, :controller=>:management
    t.action :subscription_delete, :controller=>:management, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  create_kame(:entity_sales, :model=>:sales, :conditions=>{:company_id=>['@current_company.id'], :client_id=>['session[:current_entity_id]']}, :line_class=>'RECORD.state', :children=>:lines, :per_page=>5, :order=>"created_on DESC") do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:sale}, :children=>:label
    t.column :full_name, :through=>:responsible, :children=>false
    t.column :created_on, :children=>false
    t.column :state_label, :children=>false
    t.column :paid_amount, :children=>false
    t.column :amount
    t.action :sale, :url=>{:controller=>:management, :format=>:pdf}, :image=>:print
    # t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:sale}
    t.action :sale_duplicate, :controller=>:management, :method=>:post
    t.action :sale_update, :controller=>:management, :if=>"RECORD.draft? "
    t.action :sale_delete, :controller=>:management, :if=>"RECORD.aborted? ", :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  
  create_kame(:entity_events, :model=>:events, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity_id]']}, :order=>"created_at DESC") do |t|
    t.column :name, :through=>:nature
    t.column :reason
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
    t.column :duration
    t.column :location
    t.column :started_at
    t.action :event_update
    t.action :event_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  create_kame(:entity_cashes, :model => :cashes, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity_id]']}) do |t|
    t.column :name
    t.column :number
    t.column :iban_label
    t.action :cash_update, :controller => :finances
    t.action :cash_delete, :controller => :finances, :method=>:delete, :confirm=> :are_you_sure_you_want_to_delete 
  end
  
#   create_kame(:entity_sales_invoices, :model=>:sales_invoices, :conditions=>{:company_id=>['@current_company.id'], :client_id=>['session[:current_entity_id]']}, :line_class=>'RECORD.status', :per_page=>5, :children=>:lines, :order=>"created_on DESC") do |t|
#     t.column :number, :url=>{:controller=>:management, :action=>:sales_invoice}, :children=>:label
#     t.column :number, :through=>:sale, :url=>{:controller=>:management, :action=>:sale}, :children=>false
#     # t.column :full_name, :through=>:client
#     # t.column :address, :through=>:contact
#     t.column :created_on, :children=>false
#     t.column :state_label, :through=>:sale, :children=>false
#     t.column :pretax_amount
#     t.column :amount
#     # t.column :credit
#     t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:sales_invoice}
#     # t.action :controller=>:management, :sale_cancel, :if=>'RECORD.credit != true and @current_user.credits'
#     # t.action :controller=>:management, :sale_cancel, :if=>'RECORD.credit != true and @current_user.credits'
#   end
  
  create_kame(:entity_mandates, :model=>:mandates, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity_id]']}) do |t|
    t.column :title
    t.column :organization, :url=>{:action=>:mandates}
    t.column :family
    t.column :started_on, :datatype=>:date
    t.column :stopped_on, :datatype=>:date
    t.action :mandate_update, :image=>:update
    t.action :mandate_delete, :image=>:delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  create_kame(:entity_incoming_payments, :model=>:incoming_payments, :conditions=>{:company_id=>['@current_company.id'], :payer_id=>['session[:current_entity_id]']}, :order=>"created_at DESC", :line_class=>"(RECORD.used_amount!=RECORD.amount ? 'warning' : nil)") do |t|
    #t.column :id, :url=>{:controller=>:management, :action=>:incoming_payment}
    t.column :number, :url=>{:controller=>:finances, :action=>:incoming_payment}
    t.column :paid_on
    t.column :label, :through=>:responsible
    t.column :name, :through=>:mode
    t.column :bank
    # t.column :account_number
    t.column :check_number
    t.column :used_amount
    t.column :amount, :url=>{:controller=>:finances, :action=>:incoming_payment}
    t.column :number, :through=>:deposit, :url=>{:controller=>:finances, :action=>:deposit}
    t.action :incoming_payment_update, :controller=>:finances, :if=>"RECORD.deposit.nil\?"
    t.action :incoming_payment_delete, :controller=>:finances, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.used_amount.to_f<=0"
  end


  create_kame(:entity_outgoing_payments, :model=>:outgoing_payments, :conditions=>{:company_id=>['@current_company.id'], :payee_id=>['session[:current_entity_id]']}, :order=>"created_at DESC", :line_class=>"(RECORD.used_amount!=RECORD.amount ? 'warning' : nil)") do |t|
    t.column :number, :url=>{:controller=>:finances, :action=>:outgoing_payment}
    t.column :paid_on
    t.column :label, :through=>:responsible
    t.column :name, :through=>:mode
    t.column :check_number
    t.column :used_amount
    t.column :amount, :url=>{:controller=>:finances, :action=>:outgoing_payment}
    t.action :outgoing_payment_update, :controller=>:finances
    t.action :outgoing_payment_delete, :controller=>:finances, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.used_amount.to_f<=0"
  end


  create_kame(:entity_observations, :model=>:observations, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity_id]']},:line_class=>'RECORD.status', :per_page=>5) do |t|
    t.column :description
    t.column :text_importance
    t.action :observation_update
    t.action :observation_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end


  create_kame(:entity_purchases, :model=>:purchase,:conditions=>{:company_id=>['@current_company.id'], :supplier_id=>['session[:current_entity_id]']}, :line_class=>'RECORD.status') do |t|
    t.column :number ,:url=>{:controller=>:management, :action=>:purchase}
    t.column :created_on
    t.column :invoiced_on
    t.column :address, :through=>:delivery_contact
    t.column :state_label
    t.column :paid_amount
    t.column :amount
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:purchase}
    t.action :purchase_update, :controller=>:management #, :if=>'RECORD.editable'
    t.action :purchase_delete, :controller=>:management,:method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def entity
    return unless @entity = find_and_check(:entity)
    session[:current_entity_id] = @entity.id
    session[:my_entity] = params[:id]
    @key = ""
    t3e @entity.attributes
  end
  
  #
  def entity_create
    @custom_fields = @current_company.custom_fields.find(:all, :order=>:position, :conditions=>{:active=>true})
    @custom_field_data = []
    
    if request.post?
      @entity = Entity.new(params[:entity])
      @entity.company_id = @current_company.id
      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      for custom_field in @custom_fields
        attributes = params[:custom_field_datum][custom_field.id.to_s]||{}
        attributes[:custom_field_id] = custom_field.id
        attributes[:company_id] = @current_company.id
        @custom_field_data << CustomFieldDatum.new(attributes)
      end

      ActiveRecord::Base.transaction do
        if saved = @entity.save
          @entity.account(:client) if @entity.client?
          @entity.account(:supplier) if @entity.supplier?
          @entity.account(:attorney) if @entity.attorney?
          
          for datum in @custom_field_data
            datum.entity_id = @entity.id
            saved = false unless datum.save
            @entity.errors.add_from_record(datum)
          end

          @contact.entity_id = @entity.id
          saved = false unless @contact.save
          @entity.errors.add_from_record(@contact)
        end

        raise ActiveRecord::Rollback unless saved
        return if save_and_redirect(@entity, :saved=>saved)
      end

    else
      @contact = @current_company.contacts.new(:country=>@current_company.entity.country, :language=>@current_company.entity.language)
      @entity = @current_company.entities.new(:country=>@current_company.entity.country, :language=>@current_company.entity.language)
      for custom_field in @custom_fields
        @custom_field_data << @current_company.custom_field_data.new(:entity_id=>@entity.id, :custom_field_id=>custom_field.id)
      end
    end
    render_form
  end

  #
  def entity_update
    return unless @entity = find_and_check(:entity)
    session[:current_entity_id] = @entity.id
       
    @custom_fields = @current_company.custom_fields.find(:all, :order=>:position, :conditions=>{:active=>true})
    @custom_field_data = []
    @contact = @entity.default_contact||@entity.contacts.new
    
    if request.post? and @entity
      
      for custom_field in @custom_fields
        attributes = params[:custom_field_datum][custom_field.id.to_s]||{}
        attributes[:custom_field_id] = custom_field.id
        attributes[:company_id] = @current_company.id
        datum = CustomFieldDatum.find_by_entity_id_and_custom_field_id(@entity.id, custom_field.id)
        if datum
          datum.attributes = attributes 
          @custom_field_data << datum
        else
          @custom_field_data << CustomFieldDatum.new(attributes)
        end
      end
     
      ActiveRecord::Base.transaction do
        saved = @entity.update_attributes(params[:entity])
        if saved
          @entity.account(:client) if @entity.client?
          @entity.account(:supplier) if @entity.supplier?
          @entity.account(:attorney) if @entity.attorney?
          
          for datum in @custom_field_data
            datum.entity_id = @entity.id
            saved = false unless datum.save
            @entity.errors.add_from_record(datum)
          end
        end
        
        saved = false unless @contact.update_attributes(params[:contact])
        @entity.errors.add_from_record(@contact)
        raise ActiveRecord::Rollback unless saved
        redirect_to_back
      end
      
    else
      for custom_field in @custom_fields
        datum  = CustomFieldDatum.find_by_custom_field_id_and_entity_id(custom_field.id, @entity.id)
        if datum
          @custom_field_data << datum
        else
          @custom_field_data << CustomFieldDatum.new(:custom_field_id=>custom_field.id)
        end
      end
    end
    t3e @entity.attributes
    render_form
  end

  def entity_delete
    return unless @entity = find_and_check(:entity)
    if request.post? or request.delete?
      unless @entity.sales_invoices.size > 0
        @entity.destroy
      else
        notify(:cannot_delete_entity, :error)
      end
    end
    redirect_to :action=>:entities
  end

  def entities_merge
    if request.post?
      return unless @master = find_and_check(:entity, params[:merge][:master])
      return unless @double = find_and_check(:entity, params[:merge][:double])
      if @master.id == @double.id
        notify(:cannot_merge_an_entity_with_itself, :error, :now)
        return
      end
      begin
        @master.merge(@double, true)
      rescue
        notify(:cannot_merge_entities, :error, :now)
      end
    end
  end
  
  create_kame(:entity_categories, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :code
    t.column :name
    t.column :description
    t.column :by_default
    t.action :entity_category_update
    t.action :entity_category_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def entity_categories
  end

  create_kame(:category_prices, :model=>:prices, :conditions=>{:company_id=>['@current_company.id'], :active=>true, :category_id=>['session[:category]']}) do |t|
    t.column :name, :through=>:product, :url=>{:controller=>:management, :action=>:product}
    t.column :pretax_amount
    t.column :amount
    t.column :name, :through=>:tax
    t.action :price_delete, :controller=>:management, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
    
  def entity_category
    return unless @entity_category = find_and_check(:entity_category)
    session[:category] = @entity_category.id
    @category_prices_count = @current_company.prices.find(:all, :conditions=>{:active=>true, :category_id=>@entity_category.id}).size
    t3e @entity_category.attributes
  end
  
  manage :entity_categories

  manage :contacts, :entity_id=>"@current_company.entities.find(params[:entity_id]||session[:current_entity_id]).id rescue 0", :country=>"@current_company.entities.find(params[:entity_id]||session[:current_entity_id]).country rescue @current_company.entity.country", :t3e=>{:entity=>"@contact.entity.full_name"}

  create_kame(:entity_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :title
    t.column :active
    t.column :physical
    t.column :in_name
    t.action :entity_nature_update
    t.action :entity_nature_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def entity_natures
  end

  manage :entity_natures
  
  create_kame(:entity_link_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :name_1_to_2
    t.column :name_2_to_1
    t.column :propagate_contacts
    t.column :symmetric
    t.action :entity_link_nature_update
    t.action :entity_link_nature_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def entity_link_natures
  end

  manage :entity_link_natures

  create_kame(:entity_links, :conditions=>['stopped_on IS NULL AND company_id = ? AND (entity_1_id = ? OR entity_2_id = ?)' , ['@current_company.id'],['session[:current_entity_id]'],['session[:current_entity_id]']], :per_page=>5) do |t|
    t.column :description, :through=>:entity_1, :url=>{:action=>:entity}
    t.column :name_1_to_2, :through=>:nature
    t.column :description, :through=>:entity_2, :url=>{:action=>:entity}
    t.column :comment
    t.action :entity_link_update
    t.action :entity_link_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  

  manage :entity_links, :entity_1_id=>'@current_company.entities.find(params[:entity_id]).id rescue 0'

  #
  def self.mandates_conditions(options={}) 
    code = ""
    code += "conditions = ['mandates.company_id=?', @current_company.id]\n"
    code += "if session[:mandates].is_a? Hash\n"
    code += "  unless session[:mandates][:organization].blank? \n"
    code += "    conditions[0] += ' AND organization = ?'\n"
    code += "    conditions << session[:mandates][:organization] \n"
    code += "  end \n"
    code += "  unless session[:mandates][:date].blank? \n"
    code += "    conditions[0] += ' AND (? BETWEEN COALESCE(started_on, stopped_on, ?)  AND COALESCE(stopped_on, ?) )'\n"
    code += "    conditions << session[:mandates][:date].to_s \n"
    code += "    conditions << session[:mandates][:date].to_s \n"
    code += "    conditions << session[:mandates][:date].to_s \n"
    code += "  end \n"
    code += "end \n"
    code += "conditions \n"
    code
  end


  create_kame(:mandates, :conditions=>mandates_conditions) do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity}
    t.column :title
    t.column :organization
    t.column :family
    t.column :started_on
    t.column :stopped_on
    t.action :mandate_update, :image=>:update
    t.action :mandate_delete, :image=>:delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  
  #
  def mandates
    @entities = @current_company.entities    
    @organizations = @current_company.mandates.find(:all, :select=>' DISTINCT organization ')
    session[:mandates] ||= {}
    session[:mandates][:organization] = params[:organization]||session[:mandates][:organization]||''
    session[:mandates][:date] = params[:date]||session[:mandates][:date]||Date.today
  end

  manage :mandates, :entity_id=>"@current_company.entities.find(params[:entity_id]).id rescue 0"

  # this method configures mandates
  def mandates_configure
    notify(:no_existing_mandates, :now) if @current_company.mandates.size == 0
   
    filters = { :no_filters => '', :contains => '%X%', :is => 'X', :begins => 'X%', :finishes => '%X', :not_contains => '%X%', :not_is  => 'X', :not_begins => 'X%', :not_finishes => '%X' }
    shortcuts = { :fam => :family, :org => :organization, :tit => :title } 
    @filters = filters.collect{|f,k| [tc(f), f]}.sort

    if request.post?
      notify(:specify_updates, :error, :now) unless params[:columns].detect{|k,v| !v[:update].blank?}
      notify(:specify_filter, :error, :now)  unless params[:columns].detect{|k,v| !v[:filter].blank?}
      return if has_notifications?
      
      conditions = ["company_id = ?", @current_company.id]
      updates = "updated_at = CURRENT_TIMESTAMP"
      for p, v in params[:columns] do
        if v[:filter].to_sym != :no_filters
          conditions[0] += " AND LOWER(#{p}) "+(v[:filter].to_s.match(/^not_/) ? "NOT " : "").to_s+"LIKE ?"
          conditions << filters[v[:filter].to_sym].gsub(/X/, v[:search].lower.to_s)
        end
        updates += ", #{p} = '#{v[:new_value].gsub(/\'/,'\'\'').gsub(/\@...\@/){|x| '\'||'+shortcuts[x[1..-2].to_sym].to_s+'||\''}}'" if v[:update]
      end
      Mandate.update_all(updates, conditions)
    end
    
  end
  

  manage :observations, :importance=>"'normal'", :entity_id=>"@current_company.entities.find(params[:entity_id]).id rescue 0"
 

  create_kame(:event_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :text_usage
    t.column :duration
    t.action :event_nature_update
    t.action :event_nature_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def event_natures
  end

  manage :event_natures

  def change_minutes
    return unless @event_nature = find_and_check(:event_nature)
  end
  

  create_kame(:events, :conditions=>search_conditions(:events, :events=>[:duration, :location, :reason, :started_at], :users=>[:first_name, :last_name, :name], :entities=>[:full_name], :event_natures=>[:name]), :joins=>"JOIN #{User.table_name} AS users ON (#{Event.table_name}.responsible_id=users.id) JOIN #{Entity.table_name} AS entities ON (entity_id=entities.id) JOIN #{EventNature.table_name} AS event_natures ON (events.nature_id=event_natures.id)", :order=>"started_at DESC") do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity}
    t.column :duration
    t.column :location
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user} 
    t.column :name, :through=>:nature
    t.column :started_at
    t.action :event_update
    t.action :event_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  
  def events
    session[:event_key] = params[:key]||session[:event_key]
  end
  
  manage :events, :responsible_id=>'@current_user.id', :entity_id=>"@current_company.entities.find(params[:entity_id]).id rescue 0", :duration=>"@current_company.event_natures.first.duration rescue 0", :started_at=>"Time.now.to_s(:db)"


  def entities_export
    if request.xhr?
      render :partial=>'entities_export_condition'
    else
      @columns = @current_company.exportable_columns
      @conditions = ["special-subscriber"] # , "special-buyer", "special-relation"]
      @conditions += Entity.exportable_columns.collect{|c| "generic-entity-#{c.name}"}.sort
      @conditions += Contact.exportable_columns.collect{|c| "generic-contact-#{c.name}"}.sort
      @conditions += ["generic-area-postcode", "generic-area-city"]
      @conditions += ["generic-district-name"]
      if request.post?
        from  = " FROM #{Entity.table_name} AS entity"
        from += " LEFT JOIN #{Contact.table_name} AS contact ON (contact.entity_id=entity.id AND contact.by_default IS TRUE AND contact.deleted_at IS NULL AND contact.company_id=#{@current_company.id})"
        from += " LEFT JOIN #{Area.table_name} AS area ON (contact.area_id=area.id AND area.company_id=#{@current_company.id})"
        from += " LEFT JOIN #{District.table_name} AS district ON (area.district_id=district.id AND district.company_id=#{@current_company.id})"
        where = " WHERE entity.active AND entity.company_id=#{@current_company.id}"
        select_array = []
        for k, v in params[:columns].select{|k,v| v[:check].to_i == 1}.sort{|a,b| a[1][:order].to_i<=>b[1][:order].to_i}
          if k.match(/^custom_field\-/)
            id = k.split('-')[1][2..-1].to_i
            if custom_field = @current_company.custom_fields.find_by_id(id)
              from += " LEFT JOIN #{CustomFieldDatum.table_name} AS _c#{id} ON (entity.id=_c#{id}.entity_id AND _c#{id}.custom_field_id=#{id} AND _c#{id}.company_id=#{@current_company.id})"
              if custom_field.nature == "choice"
              select_array << [ "_cc#{id}.value AS custom_field_#{id}", v[:label]]
                from += " LEFT JOIN #{CustomFieldChoice.table_name} AS _cc#{id} ON (_cc#{id}.id=_c#{id}.choice_value_id)"
              else
                select_array << [ "_c#{id}.#{custom_field.nature}_value AS custom_field_#{id}", v[:label]]
              end
            end
          else
            select_array << [k.gsub('-', '.'), v[:label]]
          end
        end
        if params[:conditions]
          code = params[:conditions].collect do |id, preferences|
            condition = preferences[:type]
            expr = if condition == "special-subscriber"
                     if nature = @current_company.subscription_natures.find_by_id(preferences[:nature])
                       subn = preferences[preferences[:nature]]
                       products = (subn[:products]||{}).select{|k,v| v.to_i==1 }.collect{|k,v| k}
                       products = "product_id IN (#{products.join(', ')})" if products.size > 0
                       products = "#{products+' OR ' if products.is_a?(String) and subn[:no_products]}#{'product_id IS NULL' if subn[:no_products]}"
                       products = " AND (#{products})" unless products.blank?
                       subscribed_on = ""
                       if subn[:use_subscribed_on]
                         subscribed_on = " AND ("+
                           if nature.period? 
                             x = subn[:subscribed_on].to_date rescue Date.today
                             "'"+ActiveRecord::Base.connection.quoted_date(x)+"'"
                           else
                             subn[:subscribed_on].to_i.to_s
                           end+" BETWEEN #{nature.start} AND #{nature.finish})"
                       end
                       timestamp = ""
                       if condition[:use_timestamp]
                         x = condition[:timestamp][:started_on].to_date rescue Date.today
                         y = condition[:timestamp][:stopped_on].to_date rescue Date.today
                         timestamp = " AND (created_at BETWEEN '#{ActiveRecord::Base.connection.quoted_date(x)}' AND '#{ActiveRecord::Base.connection.quoted_date(y)}')"
                       end
                       "entity.id IN (SELECT entity_id FROM #{Subscription.table_name} AS subscriptions WHERE nature_id=#{nature.id} AND company_id=#{@current_company.id}"+products+subscribed_on+timestamp+")"
                     else
                       "true"
                     end
                   elsif condition.match(/^generic/)
                     klass, attribute = condition.split(/\-/)[1].classify.constantize, condition.split(/\-/)[2]
                     column = klass.columns_hash[attribute]
                     ListingNode.condition(condition.split(/\-/)[1..2].join("."), preferences[:comparator], preferences[:comparated], column.sql_type)
                   end
            "\n"+(preferences[:reverse].to_i==1 ? "NOT " : "")+"(#{expr})"
          end.join(params[:check] == "and" ? " AND " : " OR ")
          where += " AND (#{code})"
        end
        select = "SELECT "+select_array.collect{|x| x[0]}.join(", ")
        query = select+"\n"+from+"\n"+where

        result = ActiveRecord::Base.connection.select_rows(query)
        result.insert(0, select_array.collect{|x| x[1]})
        csv_string = FasterCSV.generate do |csv|
          for line in result
            csv << line
          end
        end
        send_data(csv_string, :filename=>'export.csv', :type=>Mime::CSV)
      end
    end
  end



  def entities_import
    @step = params[:id].to_sym rescue :upload
    if @step == :upload
      # @formats = Spreet.formats.collect{|f| [tg("formats.#{f}"), f]}
      @formats = [["CSV", :csv]] # , ["CSV Excel", :xcsv], ["XLS Excel", :xls], ["OpenDocument", :ods]]
      if request.post? and params[:upload]
        data = params[:upload]
        file = "#{Rails.root.to_s}/tmp/uploads/entities_import_#{data.original_filename.gsub(/[^\w]/,'_')}"
        File.open(file, "wb") { |f| f.write(data.read)}
        session[:entities_import_file] = file
        redirect_to :action=>:entities_import, :id=>:columns
      end
    elsif @step == :columns
      unless File.exist?(session[:entities_import_file].to_s)
        redirect_to :action=>:entities_import, :id=>:upload
      end
      csv = FasterCSV.open(session[:entities_import_file])
      @columns = csv.shift
      @first_line = csv.shift
      @options = @current_company.importable_columns
      if request.post?
        all_columns = params[:columns].dup.delete_if{|k,v| v.match(/^special-dont_use/) or v.blank?}
        columns = params[:columns].delete_if{|k,v| v.match(/^special-/) or v.blank?}
        if (columns.values.size - columns.values.uniq.size) > 0
          notify(:columns_are_already_uses, :error, :now)
          return
        end
        cols = {}
        columns = all_columns
        for prefix in columns.values.collect{|x| x.split(/\-/)[0]}.uniq
          cols[prefix.to_sym] = {}
          columns.select{|k,v| v.match(/^#{prefix}-/)}.each{|k,v| cols[prefix.to_sym][k.to_s] = v.split(/\-/)[1].to_sym}
        end
        cols[:entity] ||= {}
        if cols[:entity].keys.size <= 0 or not cols[:entity].values.detect{|x| x == :name}
          notify(:entity_columns_are_needed, :error, :now)
          return
        end
        # raise Exception.new columns.inspect+"\n"+cols.inspect
        session[:entities_import_cols] = cols
        redirect_to :action=>:entities_import, :id=>:validate
      end
    elsif @step == :validate
      file, cols = session[:entities_import_file], session[:entities_import_cols]
      if request.post?
        @report = @current_company.import_entities(file, cols, :no_simulation=>true, :ignore=>session[:entities_import_ignore])
        notify(:importation_finished, :success)
        redirect_to :action=>:entities_import, :id=>:upload
      else
        @report = @current_company.import_entities(file, cols)
        session[:entities_import_ignore] = @report[:errors].keys
      end
    end
  end

end
