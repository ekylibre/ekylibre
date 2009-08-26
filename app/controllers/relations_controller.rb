class RelationsController < ApplicationController
 
  #
  def index
    @entities = @current_company.entities
  end

  #
  def auto_complete_for_contact_line_6
    pattern = '%'+params[:contact][:line_6].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @areas = @current_company.areas.find(:all, :conditions => [ 'LOWER(name) LIKE ? ', pattern], :order => "name ASC", :limit=>12)
    render :inline => "<%=content_tag(:ul, @areas.map { |area| content_tag(:li, h(area.name)) })%>"
  end
  
  def auto_complete_for_entity_origin
    pattern = '%'+params[:entity][:origin].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @entities = @current_company.entities.find(:all, :conditions=> [ 'LOWER(origin) LIKE ?', pattern ], :order=>"origin ASC", :limit=>12)
    render :inline => "<%=content_tag(:ul, @entities.map { |entity| content_tag(:li, h(entity.origin)) })%>"
  end

  def auto_complete_for_event_location
    pattern = '%'+params[:event][:location].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @events = @current_company.events.find(:all, :conditions=> [ 'LOWER(location) LIKE ?', pattern ], :order=>"location ASC", :limit=>12)
    render :inline => "<%=content_tag(:ul, @events.map { |event| content_tag(:li, h(event.location)) })%>"
  end

  #
  def auto_complete_for_mandate_family
    pattern = '%'+params[:mandate][:family].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(family) LIKE ? ', pattern], :order => "family ASC", :select => 'DISTINCT family')
    render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.family)) })%>"
  end
   
   #
  def auto_complete_for_mandate_organization
    pattern = '%'+params[:mandate][:organization].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(organization) LIKE ? ', pattern], :order => "organization ASC", :select => 'DISTINCT organization')
    render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.organization)) })%>"
  end
  
  #
  def auto_complete_for_mandate_title
    pattern = '%'+params[:mandate][:title].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(title) LIKE ? ', pattern], :order => "title ASC", :select => 'DISTINCT title')
    render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.title)) })%>"
  end
  
  
  dyta(:areas, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :postcode
    t.column :city
    t.column :code
    t.column :name, :through=>:district
    t.column :country    
    t.action :areas_update
    t.action :areas_delete, :confirm=>:are_you_sure, :method=>:post
  end


  #
  def areas
  end

  #
  def areas_create
    if request.post?
      @area = Area.new(params[:area])
      @area.company_id = @current_company.id
      redirect_to_back if @area.save
    else
      @area = Area.new(:district_id=>params[:id])
    end
    render_form
  end
  
  #
  def areas_update
    @area = find_and_check(:area,params[:id])
    if request.post? and @area
      redirect_to :action => "areas" if @area.update_attributes(params[:area])
    end
    @title = {:value=>@area.name}
    render_form
  end
  
  #
  def areas_delete
    @area = find_and_check(:area, params[:id])
    if request.post? or request.delete?
      redirect_to :action => "areas" if @area.destroy
    end
    render_form
  end


  dyta(:districts, :children=>:areas, :conditions=>{:company_id=>['@current_company.id']}) do |t| 
    t.column :name
    t.column :code
    t.action :areas_create
    t.action :districts_update
    t.action :districts_delete, :confirm=>:are_you_sure, :method=>:post
  end

  dyli(:districts, [:name, :code])
  
  #
  def districts
    @districts_count = @current_company.districts.count
  end

  #
  def districts_create
    if request.post?
      @district = District.new(params[:district])
      @district.company_id = @current_company.id
      redirect_to_back if @district.save
    else
      @district = District.new
    end
    render_form
  end
  
  #
  def districts_update
    @district = find_and_check(:district,params[:id])
    if request.post? and @district
      redirect_to :action => "districts" if @district.update_attributes(params[:district])
    end
    @title = {:value=>@district.name}
    render_form
  end

  def districts_delete
    @district = find_and_check(:district, params[:id])
    if request.post? or request.delete?
      redirect_to :action => "districts" if @district.destroy
    end
    render_form
  end


  dyta(:complements, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :nature_label
    t.column :required
    t.column :active
    t.column :choices_count, :datatype=>:integer
    t.action :complements_update
    t.action :complement_choices, :image=>:menulist, :if=>'RECORD.nature == "choice"'
  end


  def complements
  end

  def complements_create
    if request.post?
      @complement = Complement.new(params[:complement])
      @complement.company_id = @current_company.id
      if @complement.save 
        if @complement.nature=='choice'
          redirect_to :action=>:complement_choices , :id=>@complement.id
        else
          redirect_to_back
        end
        #        redirect_to_back 
      end
    else
      @complement = Complement.new
    end
    render_form
  end
  
  def complements_update
    @complement = find_and_check(:complement, params[:id])
    if request.post?
      redirect_to_back if @complement.update_attributes(params[:complement])
      #      if @complement.nature == 'choice'
      #        redirect_to :action=>:complement_choices , :id=>@complement.id
      #      elsif  @complement
      #        redirect_to_back if @complement.update_attributes(params[:complement])
      #      end
    end
    @title = {:value=>@complement.name}
    render_form
  end



  dyta(:complement_choices, :conditions=>{:company_id=>['@current_company.id'], :complement_id=>['session[:current_complement_id]']}, :order=>{'sort'=>'position'}) do |t| 
    t.column :name 
    t.column :value
    t.action :complement_choices_up, :if=>"not RECORD.first\?", :method=>:post
    t.action :complement_choices_down, :if=>"not RECORD.last\?", :method=>:post
    t.action :complement_choices_update
  end
  

  def complement_choices
    @complement = find_and_check(:complement , params[:id])
    session[:current_complement_id] = @complement.id
    @title = {:value=>@complement.name}
  end

  def complement_choices_create
    @complement = find_and_check(:complement, session[:current_complement_id])
    if request.post?
      @complement_choice = ComplementChoice.new(params[:complement_choice])
      @complement_choice.company_id = @current_company.id
      @complement_choice.complement_id = @complement.id
      if @complement_choice.save 
        redirect_to_back
      end
    else
      @complement_choice = ComplementChoice.new
    end
    @title = {:value=>@complement.name}
    render_form
  end

  def complement_choices_update
    @complement_choice = find_and_check(:complement_choice, params[:id])
    if request.post? and @complement_choice
      redirect_to_back if @complement_choice.update_attributes(params[:complement_choice])
    end
    @complement = find_and_check(:complement, @complement_choice.complement_id)
    @title = {:choice=>@complement_choice.name, :complement=>@complement.name}
    render_form
  end
  
  def complement_choices_up
    @complement_choice = find_and_check(:complement_choice, params[:id])
    if request.post? and @complement_choice
      @complement_choice.move_higher
    end
    redirect_to_current
  end
  
  def complement_choices_sort
    @complement = find_and_check(:complement, session[:current_complement_id])
    if request.post? and @complement
      @complement.sort_choices
    end
    redirect_to :action=>:complement_choices, :id=>@complement.id
  end
  
  def complement_choices_down
    @complement_choice = find_and_check(:complement_choice, params[:id])
    if request.post? and @complement_choice
      @complement_choice.move_lower
    end
    redirect_to_current
  end
  


#  dyta(:entities, :conditions=>["COALESCE(entities.code)||' '||COALESCE", ['session[:entity_key]']], :joins=>"LEFT JOIN contacts c ON (entities.id=c.entity_id AND c.active)") do |t|
#  dyta(:entities, :conditions=>"search_conditions(:attributes=>[:code, :full_name, :website], :key=>session[:entity_key])") do |t|
  dyta(:entities, :distinct=>true, :conditions=>search_conditions(:entities, :entities=>[:code, :full_name, :website], :c=>[:address, :phone, :fax, :mobile, :email, :website]), :joins=>"LEFT JOIN contacts c ON (entities.id=c.entity_id AND c.active)") do |t|
    t.column :active, :label=>'♦'
    t.column :abbreviation, :through=>:nature
    t.column :name, :url=>{:action=>:entities_display}
    t.column :first_name, :url=>{:action=>:entities_display}
    t.column :code, :url=>{:action=>:entities_display}
    t.column :line_6, :through=>:default_contact, :url=>{:action=>:entities_contacts_update}
    t.action :entities_display
    t.action :entities_print
    t.action :entities_update
    t.action :entities_delete, :method=>:post, :confirm=>:are_you_sure
  end

  dyli(:entity, :full_name, :conditions =>{:company_id=>['@current_company.id']})
  #
  def entities_print
    @entity = find_and_check(:entity, params[:id])
    return if @entity.nil?
    print(@entity, :archive=>false, :filename=>@entity.code)
  end 

  #
  def entities
    session[:entity_key] = params[:key]||session[:entity_key]
  end


  #
  def entities_print
    @entity = find_and_check(:entity, params[:id])
    return if @entity.nil?
    print(@entity, :archive=>false, :filename=>@entity.code)
  end 

  #dyta(:contacts, :conditions=>['company_id = ? AND active = true AND (entity_id = ?  OR  entity_id IN ( SELECT entity1_id FROM entity_links  INNER JOIN entity_link_natures ON entity_links.company_id = entity_link_natures.company_id WHERE entity_links.company_id = ? AND entity1_id = ? OR entity2_id = ?   AND entity_link_natures.propagate_contacts = true) OR entity_id IN  ( SELECT entity2_id FROM entity_links  INNER JOIN entity_link_natures ON entity_links.company_id = entity_link_natures.company_id WHERE entity_links.company_id = ? AND entity1_id = ? OR entity2_id = ?   AND entity_link_natures.propagate_contacts = true) )', ['@current_company.id'], ['session[:current_entity]'], ['@current_company.id'] ,['session[:current_entity]'],['session[:current_entity]'], ['@current_company.id'] ,['session[:current_entity]'],['session[:current_entity]'] ]) do |t|
  dyta(:contacts, :conditions=>['company_id = ? AND active = true AND (entity_id = ?  OR  entity_id IN ( SELECT entity1_id FROM entity_links  INNER JOIN entity_link_natures ON  entity_link_natures.propagate_contacts = true AND entity_links.nature_id = entity_link_natures.id  WHERE (entity1_id = ? OR entity2_id = ?)) OR entity_id IN  ( SELECT entity2_id FROM entity_links  INNER JOIN entity_link_natures ON entity_link_natures.propagate_contacts = true AND entity_links.nature_id = entity_link_natures.id WHERE  (entity1_id = ? OR entity2_id = ?) ) )', ['@current_company.id'], ['session[:current_entity]'],['session[:current_entity]'],['session[:current_entity]'],['session[:current_entity]'],['session[:current_entity]'] ]) do |t|
    
    t.column :address, :url=>{:action=>:entities_contacts_update}
    t.column :phone
    t.column :fax
    t.column :mobile
    t.column :email
    t.column :website
    t.column :default
    t.column :code, :through=>:entity, :url=>{:action=>:entities_display}, :label=>tc(:entity_id)
    t.action :entities_contacts_update  
    t.action :entities_contacts_delete  , :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:entity_subscriptions, :conditions=>{:company_id => ['@current_company.id'], :entity_id=>['session[:current_entity]']}, :model=>:subscriptions, :order=>{'sort'=>'stopped_on DESC, first_number', 'dir'=>'DESC'}, :line_class=>"(RECORD.active? ? 'enough' : '')") do |t|
    t.column :name, :through=>:nature
    t.column :start
    t.column :finish
    t.column :number, :through=>:invoice, :url=>{:action=>:invoices_display, :controller=>:management}
    t.column :number, :through=>:sale_order, :url=>{:action=>:sales_details, :controller=>:management}
    t.column :address, :through=>:contact
    t.column :quantity, :datatype=>:decimal
    t.column :suspended
  end

  dyta(:entity_sales, :model=>:sale_orders, :conditions=>['company_id=? AND client_id=?', ['@current_company.id'], ['session[:current_entity]']], :order=>{'sort'=>'created_on', 'dir'=>'desc'} ,  :children=>:lines, :per_page=>5) do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:sales_details}, :children=>:product_name
    t.column :full_name, :through=>:responsible, :children=>false
    t.column :created_on, :children=>false
    t.column :text_state, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end
  

  dyta(:entity_events, :model=>:events, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
    t.column :name, :through=>:nature
    t.column :reason
    t.column :full_name, :through=>:employee
    t.column :duration
    t.column :location
    t.column :started_at
    t.action :events_update
    t.action :events_delete, :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:entity_bank_accounts, :model => :bank_accounts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
    t.column :name
    t.column :number
    t.column :iban_label
    t.action :bank_accounts_update, :controller => :accountancy
    t.action :bank_accounts_delete, :controller => :accountancy, :method=>:post, :confirm=> :are_you_sure 
  end
  
  dyta(:client_invoices, :model=>:invoices, :conditions=>{:company_id=>['@current_company.id'], :client_id=>['session[:current_entity]']}, :line_class=>'RECORD.status', :per_page=>5,:children=>:lines, :order=>{'sort'=>'number', 'dir'=>'desc'}) do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:invoices_display}, :children=>:product_name
    #t.column :full_name, :through=>:client
    #t.column :address, :through=>:contact
    t.column :created_on, :children=>false
    t.column :amount
    t.column :amount_with_taxes
    #t.column :credit
    # t.action :controller=>:management, :invoices_cancel, :if=>'RECORD.credit != true and @current_user.credits'
  end

  dyta(:observations, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']},:line_class=>'RECORD.status', :per_page=>5) do |t|
    t.column :description
    t.column :text_importance
    t.action :observations_update
    t.action :observations_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def entities_display
    @entity = find_and_check(:entity, params[:id])
    return if @entity.nil?
    #     @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
    #     if @entity.nil?
    #       flash[:error] = tc('unfound_entity')
    #       redirect_to :action=>:entities
    #       return
    #     end
    session[:current_entity] = @entity.id
    @sale_orders_number = SaleOrder.count(:conditions=>{:company_id=>@current_company.id, :client_id=>params[:id]})
    @key = ""
    @invoices_count = @entity.invoices.size
    # @meetings_count = @current_company.meetings.find(:all, :conditions=>{:entity_id=>@entity.id}).size
    @events_count = @current_company.events.find(:all, :conditions=>{:entity_id=>@entity.id}).size
    session[:my_entity] = params[:id]
    @contact = Contact.new
    @contacts_count = @entity.contacts.find(:all, :conditions=>{:active=>true}).size
    @bank_accounts_count = @entity.bank_accounts.find(:all,:conditions=>{:company_id=>@current_company.id}).size
    @observations_count = @entity.observations.find(:all,:conditions=>{:company_id=>@current_company.id}).size
    @mandates_count = @entity.mandates.count(:conditions=>{:company_id=>@current_company.id})
    @entity_links = @current_company.entity_links.find(:all, :conditions=>["stopped_on IS NULL AND (entity1_id = ? OR entity2_id = ?)",@entity.id, @entity.id]).size
    @title = {:value=>@entity.full_name}
  end

  
  def client_informations
    if params[:entity_client] == 1
      @client = 1
    else
      @client = 0
    end
  end

  #
  def entities_create
    @complements = @current_company.complements.find(:all,:order=>:position)
    @complement_data = []
    
    @client_accounts = @current_company.accounts.find(:all, :conditions => ["number LIKE ?", @current_company.parameter('accountancy.third_accounts.clients').value.to_s+'%'])
    @supplier_accounts = @current_company.accounts.find(:all, :conditions => ["number LIKE ?", @current_company.parameter('accountancy.third_accounts.suppliers').value.to_s+'%'])
    
    if request.post?
      
      @entity = Entity.new(params[:entity])
      @entity.company_id = @current_company.id

      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      @contact.norm = @current_company.address_norms[0]
    
           
      for complement in @complements
        attributes = params[:complement_datum][complement.id.to_s]||{}
        attributes[:complement_id] = complement.id
        attributes[:company_id] = @current_company.id
        @complement_data << ComplementDatum.new(attributes)
      end

      ActiveRecord::Base.transaction do
        saved = @entity.save

        if saved
          
          unless params[:entity][:client].to_i.zero?
            if params[:entity][:client_account_id].to_i.zero?
              account = @entity.create_update_account(:client) 
              @entity.client_account_id = account.id
            else
              @entity.client_account_id = params[:entity][:client_account_id]
            end
          end
          
          unless params[:entity][:supplier].to_i.zero?
            if params[:entity][:supplier_account_id].to_i.zero?
              account =@entity.create_update_account(:supplier)
              @entity.supplier_account_id = account.id
            else
              @entity.supplier_account_id = params[:entity][:supplier_account_id]
            end
          end
          
          for datum in @complement_data
            datum.entity_id = @entity.id
            saved = false unless datum.save
            datum.errors.each_full do |msg|
              @entity.errors.add_to_base(msg)
            end
          end

          @contact.entity_id = @entity.id
          saved = false unless @contact.save
          @contact.errors.each_full do |msg|
            @entity.errors.add_to_base(msg)
          end
                    
        end

        raise ActiveRecord::Rollback unless saved
        if session[:history][1].to_s.include? "relations"
          redirect_to :action=>:entities_display, :id=>@entity.id
        else
          redirect_to_back
        end
      end

    else
      @contact = @current_company.contacts.new(:country=>'fr', :default=>true)
      @entity = @current_company.entities.new(:country=>'fr')
      for complement in @complements
        @complement_data << @current_company.complement_data.new(:entity_id=>@entity.id, :complement_id=>complement.id)
      end
    end
    
    
    render_form
  end

  #
  def entities_update
    @entity = find_and_check(:entity,params[:id])
    session[:current_entity] = @entity.id
   
    
    @complements = @current_company.complements.find(:all,:order=>:position)
    @complement_data = []
    @contact = Contact.find(:first, :conditions=>{:company_id=>@current_company.id, :entity_id=>@entity.id, :default=>true})||Contact.new(:entity_id=>@entity.id,:company_id=>@current_company.id, :norm_id=>@current_company.address_norms[0].id)
    
    @client_accounts = @current_company.accounts.find(:all, :conditions => ["number LIKE ?", '411%'])
    @supplier_accounts = @current_company.accounts.find(:all, :conditions => ["number LIKE ?", '401%'])
    
    if request.post? and @entity
      
      for complement in @complements
        attributes = params[:complement_datum][complement.id.to_s]||{}
        attributes[:complement_id] = complement.id
        attributes[:company_id] = @current_company.id
        datum = ComplementDatum.find_by_entity_id_and_complement_id(@entity.id, complement.id)
        if datum
          datum.attributes = attributes 
          @complement_data << datum
        else
          @complement_data << ComplementDatum.new(attributes)
        end
      end
     
      ActiveRecord::Base.transaction do
        saved = @entity.update_attributes(params[:entity])
        if saved
          unless params[:entity][:client].to_i.zero?
            if params[:entity][:client_account_id].to_i.zero?
              account = @entity.create_update_account(:client) 
              @entity.update_attribute(:client_account_id, account.id)
            end
          end
          
          unless params[:entity][:supplier].to_i.zero?
            if params[:entity][:supplier_account_id].to_i.zero?
              account = @entity.create_update_account(:supplier) 
              @entity.update_attribute(:supplier_account_id, account.id)
            end
          end
          
          for datum in @complement_data
            datum.entity_id = @entity.id
            saved = false unless datum.save
            datum.errors.each_full do |msg|
              @entity.errors.add_to_base(msg)
            end
          end
        end
        
        saved = false unless @contact.update_attributes(params[:contact])
        @contact.errors.each_full do |msg|
          @entity.errors.add_to_base(msg)
        end
        raise ActiveRecord::Rollback unless saved
        redirect_to_back
      end
      
    else
      for complement in @complements
        datum  = ComplementDatum.find_by_complement_id_and_entity_id(complement.id, @entity.id)
        if datum
          @complement_data << datum
        else
          @complement_data << ComplementDatum.new(:complement_id=>complement.id)
        end
      end
    end
    @title = {:value=>@entity.full_name}
    render_form
  end

  def entities_delete
    if request.post? or request.delete?
      @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
      @id = params[:id]
      unless @entity.invoices.size > 0
        @id = params[:id]
        Entity.destroy(@id) if @entity
        #        Entity.delete(@id) if @entity
      else
        flash[:warning]=lc(:entities_delete_permission)
      end
    end
    redirect_to :action=>:entities
  end

  def entities_merge
    if request.post?
      @master = find_and_check(:entity, params[:merge][:master])
      @double = find_and_check(:entity, params[:merge][:double])
      if @master.id == @double.id
        flash[:error] = tc 'errors.cannot_merge_an_entity_with_itself'
        return
      end
      @master.merge(@double, true)
      begin
      rescue
        flash[:error] = tc('errors.cannot_merge_entities')
      end
    end
  end
  
  dyta(:entity_categories, :conditions=>{:company_id=>['@current_company.id'], :deleted=>false}) do |t|
    t.column :code
    t.column :name
    t.column :description
    t.column :default
    t.action :entity_categories_display
    t.action :entity_categories_update
    t.action :entity_categories_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def entity_categories
  end

  def entity_categories_create
    @entity_category = EntityCategory.new
    if request.post?
      @entity_category = EntityCategory.new(params[:entity_category])
      @entity_category.company_id = @current_company.id
      redirect_to_back if @entity_category.save
    end
    render_form
  end

  def entity_categories_update
    @entity_category = EntityCategory.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post?
      redirect_to :action=>:entity_categories if @entity_category.update_attributes!(params[:entity_category])
    end
    @title = {:value=>@entity_category.name}
    render_form
  end

  def entity_categories_delete
    @entity_category = EntityCategory.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? or request.delete?
      redirect_to :action=>:entity_categories if @entity_category.destroy
    end
  end

  dyta(:category_prices, :model=>:prices, :conditions=>{:company_id=>['@current_company.id'], :active=>true, :category_id=>['session[:category]']}) do |t|
    t.column :name, :through=>:product, :url=>{:controller=>:management, :action=>:products_display}
    t.column :amount
    t.column :amount_with_taxes
    t.column :name, :through=>:tax
    t.action :prices_delete, :controller=>:management, :method=>:post, :confirm=>:are_you_sure
  end
  
  
  def entity_categories_display
    @entity_category = find_and_check(:entity_category, params[:id])
    session[:category] = @entity_category.id
    @category_prices_count = @current_company.prices.find(:all, :conditions=>{:active=>true, :category_id=>@entity_category.id}).size
    @title = {:value=>@entity_category.name}
  end
  

  def entities_contacts_create
    @entity = find_and_check(:entity, params[:id]||session[:current_entity])
    if request.post?
      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      @contact.norm = @current_company.address_norms[0]
      @contact.entity_id = @entity.id  
      redirect_to_back if @contact.save
    else
      # this line has been added temporarly.
      @contact = Contact.new
      # @contact.name = (@entity.contacts.size>0 ? tc(:second_contact) : tc(:first_contact) )
      @entity ||= @current_company.entity 
      @contact.country = @entity.country
    end
    @title = {:value=>@entity.full_name}
    render_form
  end

  def entities_contacts_update
    @contact = Contact.find_by_id_and_company_id(params[:id], @current_company.id)
    @entity = @contact.entity # Entity.find_by_id_and_company_id(session[:current_entity], @current_company.id)
    @id = @contact.entity_id
    
    #    raise Exception.new('entity:'+@contact.entity.inspect)
    if request.post? and @contact
      redirect_to_back if @contact.update_attributes(params[:contact]) # @contact.update_attributes(params[:contact])
    end
    @title = {:entity=>@entity.full_name}
    render_form
  end
  
  def entities_contacts_delete
    if request.post? or request.delete?
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      if @contact
        @contact.active = false
        @contact.save
      end
      redirect_to_current
    end
  end
  

  dyta(:entity_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :abbreviation
    t.column :active
    t.column :physical
    t.column :in_name
    t.action :entities_natures_update
    t.action :entities_natures_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def entities_natures
  end

  def entities_natures_create
    if request.post?
      @entity_nature = EntityNature.new(params[:entity_nature])
      @entity_nature.company_id = @current_company.id
      redirect_to_back if @entity_nature.save
    else
      @entity_nature = EntityNature.new
    end
    render_form
  end
  
  def entities_natures_update
    @entity_nature = find_and_check(:entity_nature, params[:id])
    if request.post? and @entity_nature
      params[:entity_nature].delete :company_id
      redirect_to_back if @entity_nature.update_attributes(params[:entity_nature])
    end
    @title = {:value=>@entity_nature.name}
    render_form
  end

  def entities_natures_delete
    if request.post? or request.delete?
      @entity_nature = find_and_check(:entity_nature, params[:id])
      unless @entity_nature.entities.size > 0
        @entity_nature.destroy
      else
        flash[:warning]=tc(:entities_natures_delete_permission)
      end
    end
    redirect_to :action=>:entities_natures
  end
  
  dyta(:entity_link_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :name_1_to_2
    t.column :name_2_to_1
    t.column :propagate_contacts
    t.column :symmetric
    t.action :entity_link_natures_update
  end

  def entity_link_natures
  end

  def entity_link_natures_create
    if request.post?
      @entity_link_nature = EntityLinkNature.new(params[:entity_link_nature])
      @entity_link_nature.company_id = @current_company.id
      redirect_to_back if @entity_link_nature.save
    else
      @entity_link_nature = EntityLinkNature.new
    end
    render_form
  end

  def entity_link_natures_update
    @entity_link_nature = find_and_check(:entity_link_nature, params[:id])
    if request.post? and @entity_link_nature
      params[:entity_link_nature].delete :company_id
      redirect_to_back if @entity_link_nature.update_attributes(params[:entity_link_nature])
    end
    @title = {:value=>@entity_link_nature.name}
    render_form
  end


  dyta(:entity_links, :conditions=>['stopped_on IS NULL AND company_id = ? AND (entity1_id = ? OR entity2_id = ?)' , ['@current_company.id'],['session[:current_entity]'],['session[:current_entity]']], :per_page=>5) do |t|
    t.column :full_name, :through=>:entity1, :url=>{:action=>:entities_display}
    t.column :name_1_to_2, :through=>:nature
   # t.column :name_2_to_1, :through=>:nature
    t.column :full_name, :through=>:entity2, :url=>{:action=>:entities_display}
    t.column :comment
    t.action :entity_links_update
    t.action :entity_links_delete, :method=>:post, :confirm=>:are_you_sure
  end
  

  def entity_links_create
    if request.post?
      @entity_link = EntityLink.new(:comment=>params[:entity_link][:comment], :nature_id=>params[:entity_link][:nature_id].to_i)
      if params[:entity_link][:nature_id].include?("-R")
        @entity_link.entity2_id = session[:current_entity]
        @entity_link.entity1_id = params[:entity_link][:entity2_id]
      else
        @entity_link.entity2_id = params[:entity_link][:entity2_id]
        @entity_link.entity1_id = session[:current_entity]
      end
      @entity_link.company_id = @current_company.id
      redirect_to_back if @entity_link.save
    else
      @entity_link = EntityLink.new
      @entity = find_and_check(:entity, session[:current_entity])
    end
    @entity = find_and_check(:entity, session[:current_entity])
    @title = {:name=>@entity.full_name}
    render_form
  end


  def entity_links_update
    @entity_link = find_and_check(:entity_link, params[:id])
    @entity = find_and_check(:entity, @entity_link.entity1_id)
    if request.post?
      redirect_to_back if @entity_link.update_attributes(params[:entity_link])
    end
    render_form
  end

  def entity_links_delete
    @entity_link = find_and_check(:entity_link, params[:id])
    if request.post?
      redirect_to_current if @entity_link.update_attributes(:stopped_on=>Date.today)
    end
  end


   #
  def self.mandates_conditions(options={}) 
    code = ""
    code += "conditions = ['mandates.company_id=?', @current_company.id.to_s]\n"
    code += "unless session[:mandates][:organization].blank? \n"
    code += "conditions[0] += ' AND organization = ?'\n"
    code += "conditions << session[:mandates][:organization] \n"
    code += "end \n"
             
    code += "unless session[:mandates][:date].blank? \n"
    code += "conditions[0] += 'AND (? BETWEEN started_on AND stopped_on)'\n"
    code += "conditions << session[:mandates][:date].to_s \n"
    code += "end \n"
    code += "conditions \n"

    code
  end


  dyta(:mandates, :conditions=>mandates_conditions) do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entities_display}
    t.column :title
    t.column :organization
    t.column :family
    t.column :started_on
    t.column :stopped_on
    t.action :mandates_update, :image=>:update
    t.action :mandates_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  #
  def mandates
   
    if mandate = Mandate.find_by_company_id_and_id(@current_company.id, params[:id])
      params[:organization] = mandate.organization
    end
    @entities = @current_company.entities
    unless @entities.size > 0 
      flash[:message] = tc('messages.need_entities_to_consult_mandates')
      redirect_to :action => :entities_create
      return
    end
    @organizations = @current_company.mandates.find(:all, :select=>' DISTINCT organization ')
    
    session[:mandates] ||= {}
    session[:mandates][:organization] = params[:organization] || '' #if params[:organization] #- Aucune organisation ---" 
    session[:mandates][:date] = params[:date]||Date.today
  
  end
  
  dyta(:entity_mandates, :model=>:mandates, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
    t.column :title
    t.column :organization, :url=>{:action=>:mandates}
    t.column :family
    t.column :started_on, :datatype=>:date
    t.column :stopped_on, :datatype=>:date
    t.action :mandates_update, :image=>:update
    t.action :mandates_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end
  

#   def configure_mandates()
#     @mandates=[]

#     @current_company.mandates.find(:all, :select => 'DISTINCT family, organization, title').each do |mandate|
#       @mandates << [mandate.family, mandate.organization, mandate.title]
#     end
    
#   end
   
  #
 # def configure_mandates_family()
    #     params["families"].each do |key, value|
#       if value["new_name"].to_s != value["former_name"].to_s
#         @current_company.mandates.update_all("family = '"+value["new_name"].to_s+"'", "family LIKE '%"+value["former_name"].to_s+"%'")
#       end

#       Mandate.delete_all(:family => value["new_name"].to_s, :company_id=>@current_company.id) if value["to_delete"]
#     end
    
#     redirect_to :action => :configure_mandates
#   end

#   #
#   def configure_mandates_organization()

#     params["organizations"].each do |key, value|
#       if value["new_name"].to_s != value["former_name"].to_s
#         @current_company.mandates.update_all("organization = '"+value["new_name"].to_s+"'", "organization LIKE '%"+value["former_name"].to_s+"%'")
#       end
#      @current_company.mandates.destroy_all(:organization => value["new_name"].to_s) if value["to_delete"]
#     end
#     redirect_to :action => :configure_mandates
#   end

#   #
#   def configure_mandates_title()

#     params["titles"].each do |key, value|
#       if value["new_name"].to_s != value["former_name"].to_s
#         @current_company.mandates.update_all("title = '"+value["new_name"].to_s+"'", "title LIKE '%"+value["former_name"].to_s+"%'")
#       end
#     @current_company.mandates.destroy_all(:title => value["new_name"].to_s) if value["to_delete"]
#     end
#     redirect_to :action => :configure_mandates
#   end

  #
  def mandates_create
    @entity = find_and_check(:entity, params[:id]||session[:current_entity])
    if request.post?
      @mandate = Mandate.new(params[:mandate])
      @mandate.company_id = @current_company.id
      @mandate.entity_id = @entity.id  
      redirect_to :action=>:entities_display if @mandate.save
    else 
      @mandate = Mandate.new
    end
    render_form
  end
  
  def mandates_update
    @mandate = Mandate.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @mandate
      redirect_to :action=>:entities_display if @mandate.update_attributes(params[:mandate])
    end
    @title = {:entity=>@mandate.entity.full_name}
    render_form
  end
  
  def mandates_delete
    @mandate = Mandate.find_by_id_and_company_id(params[:id] , @current_company.id )
    if request.post? or request.delete?
      redirect_to :action=>:entities_display if @mandate.destroy
    end
  end
  
  dyta(:event_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :text_usage
    t.column :duration
    t.action :event_natures_update
    t.action :event_natures_delete, :method=>:post, :confirm=>:are_you_sure
  end

  def event_natures
    #    event_natures_list
  end

  def event_natures_create
    @event_nature = EventNature.new
    if request.post?
      #raise Exception.new params.inspect
      @event_nature = EventNature.new(params[:event_nature])
      @event_nature.company_id = @current_company.id
      redirect_to_back if @event_nature.save
    end
    render_form
  end

  def event_natures_update
    @event_nature = find_and_check(:event_nature, params[:id])
    if request.post?
      redirect_to_back if @event_nature.update_attributes!(params[:event_nature])
    end
    @title = {:value=>@event_nature.name}
    render_form
  end

  def event_natures_delete
    @event_nature = find_and_check(:event_nature, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @event_nature.update_attributes(:active=>false)
    end
  end
  
  dyta(:events, :conditions=>['company_id = ?',['@current_company.id']]) do |t|
    t.column :full_name, :through=>:entity
    t.column :duration
    t.column :location
    t.column :full_name, :through=>:employee
    t.column :name, :through=>:nature
    t.column :started_at
    t.action :events_update
    t.action :events_delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  def events
  end

  def change_minutes
    @event_nature = find_and_check(:event_nature, params[:event_nature_id])
  end
  
  def events_create
    @entity = find_and_check(:entity, params[:entity_id]) if params[:entity_id]
    @entity = find_and_check(:entity, session[:current_entity]) if @entity.nil? && session[:current_entity]
    @event = Event.new(:entity_id=>(@entity ? @entity.id : nil), :duration=>(@current_company.event_natures.size>0 ? @current_company.event_natures.find(:first).duration : 0), :started_at=>Time.now)
    @event.employee = @current_user.employee
    if request.post?
      @event = Event.new(params[:event])
      @event.company_id = @current_company.id
      redirect_to_back if @event.save
    end
    render_form
  end
  
  
  def events_update
    @event = find_and_check(:event, params[:id])
    if request.post?
      redirect_to_back if @event.update_attributes(params[:event])
    end
    @title = {:value=>@event.entity.full_name}
    render_form
  end
  
  def events_delete
    @event = find_and_check(:event, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @event.destroy
    end
  end

  @@exchange_format = [ {:name=>:entity_code, :null=>false}, 
                        {:name=>:entity_nature_name, :null=>false},
                        {:name=>:entity_name, :null=>false},
                        {:name=>:entity_first_name, :null=>true},
                        {:name=>:contact_line_2, :null=>true},
                        {:name=>:contact_line_3, :null=>true},
                        {:name=>:contact_line_4_number, :null=>true},
                        {:name=>:contact_line_4_street, :null=>true},
                        {:name=>:contact_line_5, :null=>true},
                        {:name=>:contact_line_6_code, :null=>true},
                        {:name=>:contact_line_6_city, :null=>false},
                        {:name=>:contact_phone, :null=>true},
                        {:name=>:contact_mobile, :null=>true},
                        {:name=>:contact_fax, :null=>true}, 
                        {:name=>:contact_email, :null=>true},
                        {:name=>:contact_website, :null=>true},
                        {:name=>:entity_reduction_rate, :null=>true},
                        {:name=>:entity_comment, :null=>true} ]
  
  @@exchange_format.each do |column|
    column[:label] = tc(column[:name])
  end


  def entities_export
    send_data @current_company.export_entities, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment", :filename=>'Fiches_C-F.csv'
  end



  def entities_import

    @model = @@exchange_format
    indices = {}

    @model.size.times do |index|
      indices[@model[index][:name]] = index
    end

    if request.post?
      if params[:csv_file].nil?
        flash[:warning]=tc(:you_must_select_a_file_to_import)
        redirect_to :action=>:entities_import
      else
        data = params[:csv_file][:path]
        file = "#{RAILS_ROOT}/tmp/uploads/entities_import_#{data.original_filename.gsub(/[^\w]/,'_')}"
        File.open(file, "wb") { |f| f.write(data.read)}
        i = 0
        @available_entities = []
        @unavailable_entities = []
        language = @current_company.parameter('general.language')
        FasterCSV.foreach(file) do |row|
          @entity = Entity.find_by_company_id_and_code(@current_company.id, row[indices[:entity_code]])
          if @entity.nil?
            @entity = Entity.new(:code=>row[indices[:entity_code]], :company_id=>@current_company.id, :language_id=>language.id, :nature_id=>@current_company.entity_natures[0])
            @contact = Contact.new(:default=>true, :company_id=>@current_company.id, :entity_id=>0, :norm_id=>@current_company.address_norms[0], :country=>'fr')
          else
            @contact = @current_company.contacts.find(:first, :conditions=>{:entity_id=>@entity.id, :default=>true, :deleted=>false})
          end
          
          if i!=0 
            @entity.attributes = {:nature_id=>@current_company.imported_entity_nature(row[indices[:entity_nature_name]]), :name=>row[indices[:entity_name]], :first_name=>row[indices[:entity_first_name]], :reduction_rate=>row[indices[:entity_reduction_rate]].to_s.gsub(/\,/,"."), :comment=>row[indices[:entity_comment]]}
            @contact.attributes = {:line_2=>row[indices[:contact_line_2]], :line_3=>row[indices[:contact_line_3]], :line_4_number=>row[indices[:contact_line_4_number]], :line_4_street=>row[indices[:contact_line_4_street]], :line_5=>row[indices[:contact_line_5]], :line_6=>row[indices[:contact_line_6_code]].to_s+' '+row[indices[:contact_line_6_city]].to_s, :phone=>row[indices[:contact_phone]], :mobile=>row[indices[:contact_mobile]], :fax=>row[indices[:contact_fax]] ,:email=>row[indices[:contact_email]], :website=>row[indices[:contact_website]] } if !@contact.nil?
            if !@contact.nil? 
              if !@contact.valid? or !@entity.valid?
                @unavailable_entities << [i+1, @entity.errors.full_messages, @contact.errors.full_messages]
              else
                @available_entities << [@entity, @contact]
              end
            elsif @entity.valid?
              @available_entities << [@entity, nil]
            end
          end 
          puts i if i % 100 == 0
          i += 1
        end 
        # Fin boucle FasterCSV -- Début traitement données recueillies
        if @unavailable_entities.empty?        
          for entity_contact in @available_entities
            entity = Entity.find_by_company_id_and_code(@current_company.id, entity_contact[0].code)
            if entity.nil?
              en = Entity.create!(entity_contact[0].attributes)
              ct = Contact.new( entity_contact[1].attributes) 
              ct.entity_id = en.id
              ct.save
            else
              entity.update_attributes(entity_contact[0].attributes)
              contact = @current_company.contacts.find(:first, :conditions=>{:entity_id=>entity_contact[0].id, :default=>true, :deleted=>false}) 
              contact.update_attributes(entity_contact[1].attributes) if !contact.nil?
            end
            flash[:notice]=tc(:import_succeed)
          end
        end
      end
      
    end
    
  end
  
  def observations_create
    @observation = Observation.new(:importance=>"normal")
    session[:entity_id] = params[:entity_id] if request.get?
    if request.post?
      #raise Exception.new(session[:entity_id].inspect)
      @observation = Observation.new(params[:observation])
      @observation.entity_id = session[:entity_id]
      @observation.company_id = @current_company.id
      redirect_to_back if @observation.save
    end
    render_form
  end
  
  def observations_update
    @observation = find_and_check(:observation, params[:id])
    if request.post?
      redirect_to_back if @observation.update_attributes(params[:observation])
    end
    render_form
  end
  
  def observations_delete
    @observation = find_and_check(:observation, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @observation.destroy
    end
  end
  
end
