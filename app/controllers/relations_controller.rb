class RelationsController < ApplicationController

  def index
  end

  dyta(:complements, :conditions=>{:company_id=>['@current_company.id']}, :empty=>true) do |t|
    t.column :name
    t.column :nature_label
    t.column :required
    t.column :active
    t.column :choices_count, :datatype=>:integer
    t.action :complements_update, :image=>:update
    t.action :complement_choices, :image=>:menulist, :if=>'RECORD.nature == "choice"'
    t.procedure :complements_create
  end

  dyta(:complement_choices, :conditions=>{:company_id=>['@current_company.id'], :complement_id=>['session[:current_complement_id]']}, :order=>{'sort'=>'position'}) do |t| 
    t.column :name
    t.column :value
    t.action :complement_choices_up, :if=>"not RECORD.first\?", :method=>:post
    t.action :complement_choices_down, :if=>"not RECORD.last\?", :method=>:post
    t.action :complement_choices_update
    t.procedure :complement_choices_create
    t.procedure :complement_choices_sort, {:method=>:post}
  end
  
  def complements
    access :complements
    complements_list
  end

  def complement_choices
    access :complement_choices
    @complement = find_and_check(:complement , params[:id])
    session[:current_complement_id] = @complement.id
    @title = {:value=>@complement.name}
    complement_choices_list params
  end

  def complement_choices_create
    access :complement_choices
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
    access :complement_choices
    @complement_choice = find_and_check(:complement_choice, params[:id])
    if request.post? and @complement_choice
      redirect_to_back if @complement_choice.update_attributes(params[:complement_choice])
    end
    @complement = find_and_check(:complement, @complement_choice.complement_id)
    @title = {:choice=>@complement_choice.name, :complement=>@complement.name}
    render_form
  end
  
  def complement_choices_up
    access :complement_choices
    @complement_choice = find_and_check(:complement_choice, params[:id])
    if request.post? and @complement_choice
      @complement_choice.move_higher
    end
    redirect_to_current
  end
  
  def complement_choices_sort
    access :complement_choices
    @complement = find_and_check(:complement, session[:current_complement_id])
    if request.post? and @complement
      @complement.sort_choices
    end
    redirect_to :action=>:complement_choices, :id=>@complement.id
  end
  
  def complement_choices_down
    access :complement_choices
    @complement_choice = find_and_check(:complement_choice, params[:id])
    if request.post? and @complement_choice
      @complement_choice.move_lower
    end
    redirect_to_current
  end
  
  def complements_create
    access :complements
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
    access :complements
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



  dyta(:entities, :conditions=>"search_conditions(:attributes=>[:id, :name, :code, :full_name, :website], :key=>session[:entity_key])", :empty=>true) do |t|
    t.column :name, :through=>:nature
    t.column :name, :url=>{:action=>:entities_display}
    t.column :first_name, :url=>{:action=>:entities_display}
    # t.column :full_name
    t.column :code, :url=>{:action=>:entities_display}
    # t.column :born_on
    # t.column :dead_on
    t.column :website
    t.column :created_on, :datatype=>:date
    t.column :active
    t.action :entities_display
    t.action :entities_update
    t.action :entities_print
    t.action :entities_delete, :method=>:post, :confirm=>:are_you_sure
  end


  def entities_print
    render :xil=>"#{RAILS_ROOT}/app/views/prints/xil2_test.xml", :client=>Entity.find(params[:id]||1), :output=>:pdf
  end

  
  def entities
    @size = Entity.count
    @key = params[:key]||session[:entity_key]
    session[:entity_key] = @key
    #entities_list({:attributes=>[:id, :name, :code, :full_name, :website], :key=>@key}.merge(params))
    # contacts_list({:attributes=>[:id, :fax, :mobile, :telephone], :key=>@key}.merge(params))
    #     #  entities_list params
    #     @entities = {}
    #  @contacts = {}
    #     #if request.post?
    # #      id = params[:contact][:id].to_i
    #     @key = params[:key]
    #     entities_list({:attributes=>[:id, :name], :key=>@key}.merge(params))
    # #       @person = Entity.find_by_id_and_company_id(id,@current_company.id)
    # #       @contact = Contact.find_by_id_and_company_id(id, @current_company.id)
    # #       if params[:contact][:fax] != ""
    # #         @idfound = nil
    # #         attributes = [:name, :code]
    # #         conditions = ["false"]
    # #         key_words = params[:contact][:fax].to_s.split(" ")
    # #         for attribute in attributes
    # #           for word in key_words
    # #             conditions[0] += " OR "+attribute.to_s+" ILIKE '%'||?||'%'"
    # #             conditions << word
    # #           end
    # #         end
    # #         @entities = Entity.find(:all, :conditions=>conditions)||{}
    # #         @entities << @person unless @person.blank?

    #  if @entities.size > 80
    #       flash[:warning]=lc(:too_much_result)
    #       redirect_to :action => :entities_search
    #     end
    #     #       end
    
    #     #       if params[:contact][:fax] != ""
    #     #         name = params[:contact][:fax].to_s.split(" ")
    # #         @key = params[:contact][:fax]
    # #         entities_list({:attributes=>[ :name], :key=>@key}.merge(params))
    # #         attributes = [:email, :fax, :mobile]
    # #         conditions = ["false"]
    # #         key_words = params[:contact][:fax].to_s.split(" ")
    # #         for attribute in attributes
    # #           for word in key_words
    # #             conditions[0] += " OR "+attribute.to_s+" ILIKE '%'||?||'%'"
    # #             conditions << word
    # #          end
    #   #end
    #       #  @contacts = Contact.find(:all, :conditions=>conditions) 
    #     if @contacts.size > 80
    #       flash[:warning]=lc(:too_much_result)
    #       redirect_to :action => :entities_search
    #     end 
    #     #  end
    #     # end
  end



  dyta(:contacts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]'], :active=>true}, :empty=>true) do |t|
    t.column :address, :url=>{:action=>:entities_contacts_update}
    t.column :phone
    t.column :fax
    t.column :mobile
    t.column :email
    t.column :website
    t.column :default
    t.action :entities_contacts_update , :image=>:update 
    t.action :entities_contacts_delete , :image=>:delete , :method=>:post, :confirm=>'are_you_sure'
  end


  #dyta(:entity_sales, :model=>:sale_orders, :conditions=>['company_id=? AND client_id=?', ['@current_company.id'], ['session[:current_entity]']], :order=>{'sort'=>'created_on', 'dir'=>'desc'}, :children=>:lines) do |t|
  dyta(:entity_sales, :model=>:sale_orders, :conditions=>['company_id=? AND client_id=?', ['@current_company.id'], ['session[:current_entity]']],  :children=>:lines) do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:sales_details}, :children=>:product_name
    t.column :name, :through=>:nature, :children=>false
    t.column :created_on, :children=>false
    t.column :text_state, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:entity_meetings, :model=>:meetings, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
    t.column :name, :through=>:location
    t.column :taken_place_on
    t.column :full_name, :through=>:employee
    t.column :name, :through=>:mode
    t.action :meetings_update, :image=>:update
    t.action :meetings_delete,  :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def entities_display
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
    session[:current_entity] = @entity.id
    @sale_orders_number = SaleOrder.count(:conditions=>{:company_id=>@current_company.id, :client_id=>params[:id]})
    @meetings_count = @current_company.meetings.find(:all, :conditions=>{:entity_id=>@entity.id}).size
    session[:my_entity] = params[:id]
    @contact = Contact.new
    @contacts_count = @entity.contacts.find(:all, :conditions=>{:active=>true}).size
    @title = {:value=>@entity.full_name}
  end
  
  def client_informations
    #raise Exception.new "jjjjjjjjjjjjjjjjjjjjjjjjjj"+params.inspect
   # render :partial => "client_form" if params[:entity_client] == 1
    if params[:entity_client] == 1
       @client = 1
    else
      @client =0
    end
  end

  def entities_create
    access :entities   
    @complements = @current_company.complements.find(:all,:order=>:position)
    @complement_data = []
    

    if request.post?
      #raise Exception.new params.inspect+"               "+params[:entity_meeting].inspect
      #for meeting in params[:entity_meeting]
       # raise Exception.new meeting[1].inspect if meeting[1].empty?
      #end
      @entity = Entity.new(params[:entity])
      @entity.company_id = @current_company.id
      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      @contact.norm = @current_company.address_norms[0]
      # @contact.name =  tc(:first_contact)
      
      for complement in @complements
        attributes = params[:complement_datum][complement.id.to_s]||{}
        attributes[:complement_id] = complement.id
        attributes[:company_id] = @current_company.id
        @complement_data << ComplementDatum.new(attributes)
      end

      ActiveRecord::Base.transaction do
        #raise Exception.new @entity.inspect
        saved = @entity.save
        if saved
          for datum in @complement_data
            datum.entity_id = @entity.id
            saved = false unless datum.save
            #            @entity.errors
            datum.errors.each_full do |msg|
              @entity.errors.add_to_base(msg)
            end
            #            puts '>> Datum : '+datum.errors.inspect
          end
          @contact.entity_id = @entity.id
          saved = false unless @contact.save
          @contact.errors.each_full do |msg|
            @entity.errors.add_to_base(msg)
          end
        end
        raise ActiveRecord::Rollback unless saved
        #raise Exception.new session.data.inspect
        if session[:history][1].to_s.include? "relations"
          redirect_to :action=>:entities_display, :id=>@entity.id
        else
          redirect_to_back
        end
      end
    else
      @contact = Contact.new(:country=>'fr', :default=>true)
      @entity = Entity.new(:country=>'fr')
      for complement in @complements
        @complement_data << ComplementDatum.new(:complement_id=>complement.id)
      end
    end
    render_form
  end

  def entities_update
    #raise Exception.new @operation.inspect
    access :entities
    @entity = find_and_check(:entity,params[:id])
    session[:current_entity] = @entity.id
    @complements = @current_company.complements.find(:all,:order=>:position)
    @complement_data = []
    @contact = Contact.find(:first, :conditions=>{:company_id=>@current_company.id, :entity_id=>@entity.id, :default=>true})||Contact.new(:entity_id=>@entity.id,:company_id=>@current_company.id, :norm_id=>@current_company.address_norms[0].id, :name=> tc(:first_contact))

    if request.post? and @entity
      #raise Exception.new @operation.inspect
      puts params[:complement_datum].inspect
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
#      puts @complement_data.inspect
      #raise Exception.new params[:entity].inspect+"              "+@entity.inspect
      ActiveRecord::Base.transaction do
        saved = @entity.update_attributes(params[:entity])
        if saved
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
    access :entities
    if request.post? or request.delete?
      @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
      @id = params[:id]
      unless @entity.invoices.size > 0
        @id = params[:id]
        Entity.delete(@id) if @entity
      else
        flash[:warning]=lc(:entities_delete_permission)
      end
    end
    redirect_to :action=>:entities
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
      @contact = Contact.new
      # @contact.name = (@entity.contacts.size>0 ? tc(:second_contact) : tc(:first_contact) )
      @contact.country = @entity.country
    end
    @title = {:value=>@entity.full_name}
    render_form
  end

  def entities_contacts_update
    access :contacts
    @entity = Entity.find_by_id_and_company_id(session[:current_entity], @current_company.id)
    @contact = Contact.find_by_id_and_company_id(params[:id], @current_company.id)
    @id = @contact.entity_id
    
#    raise Exception.new('entity:'+@contact.entity.inspect)
    if request.post? and @contact
      redirect_to_back if @contact.update_attributes(params[:contact]) # @contact.update_attributes(params[:contact])
    end
    @title = {:entity=>@entity.full_name}
    render_form
  end
  
  def entities_contacts_delete
    access :contacts
    if request.post? or request.delete?
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      @id = @contact.entity_id
      @contact.active = true
      @contact.default = false
      @contact.save
      redirect_to_back
    end
  end
  

  dyta(:entity_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :abbreviation
    t.column :active
    t.column :physical
    t.column :in_name
    t.action :entities_natures_update, :image=>:update
    t.action :entities_natures_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :entities_natures_create
  end

  def entities_natures
    access :entities
    entity_natures_list params
  end

  def entities_natures_create
    access :entities
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
    access :entities
    @entity_nature = find_and_check(:entity_nature, params[:id])
    if request.post? and @entity_nature
      params[:entity_nature].delete :company_id
      redirect_to_back if @entity_nature.update_attributes(params[:entity_nature])
    end
    @title = {:value=>@entity_nature.name}
    render_form
  end

  def entities_natures_delete
    access :entities
    if request.post? or request.delete?
      @entity_nature = find_and_check(:entity_nature, params[:id])
      unless @entity_nature.entities.size > 0
        @entity_nature.destroy
      else
        flash[:warning]=lc(:entities_natures_delete_permission)
      end
    end
    redirect_to_back
  end
 
  dyta(:meeting_locations, :conditions=>{:company_id=>['@current_company.id'], :active=>true}) do |t|
    t.column :name
    t.column :description
    t.action :meeting_locations_update, :image=>:update
    t.action :meeting_locations_delete,  :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def meeting_locations
    meeting_locations_list
  end
 
  def meeting_locations_create
    @meeting_location = MeetingLocation.new
    if request.post?
      @meeting_location = MeetingLocation.new(params[:meeting_location])
      @meeting_location.company_id = @current_company.id
      redirect_to_back if @meeting_location.save
    end
    render_form
  end
  
  def meeting_locations_update
    @meeting_location = find_and_check(:meeting_location, params[:id])
    if request.post?
      redirect_to_back if @meeting_location.update_attributes!(params[:meeting_location])
    end
    @title = {:value=>@meeting_location.name}
    render_form
  end

  def meeting_locations_delete
    @meeting_location = find_and_check(:meeting_location, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @meeting_location.update_attributes(:active=>false)
    end
  end

  dyta(:meeting_modes, :conditions=>{:company_id=>['@current_company.id'], :active=>true}) do |t|
    t.column :name
    t.action :meeting_modes_update, :image=>:update
    t.action :meeting_modes_delete,  :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def meeting_modes
    meeting_modes_list
  end

  def meeting_modes_create
    @meeting_mode = MeetingMode.new
    if request.post?
      #raise Exception.new params.inspect
      @meeting_mode = MeetingMode.new(params[:meeting_mode])
      @meeting_mode.company_id = @current_company.id
      redirect_to_back if @meeting_mode.save
    end
    render_form
  end

  def meeting_modes_update
    @meeting_mode = find_and_check(:meeting_mode, params[:id])
    if request.post?
      redirect_to_back if @meeting_mode.update_attributes!(params[:meeting_mode])
    end
    @title = {:value=>@meeting_mode.name}
    render_form
  end

  def meeting_modes_delete
    @meeting_mode = find_and_check(:meeting_mode, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @meeting_mode.update_attributes(:active=>false)
    end
  end
  
  dyta(:meetings, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :full_name, :through=>:entity
    t.column :name, :through=>:location
    t.column :taken_place_on
    t.column :full_name, :through=>:employee
    t.column :name, :through=>:mode
    t.action :meetings_update, :image=>:update
    t.action :meetings_delete,  :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  def meetings
    meetings_list
  end
  
  def meetings_create
    @entity = find_and_check(:entity, params[:entity_id]) if params[:entity_id]
    @entity = find_and_check(:entity, session[:current_entity]) if @entity.nil? && session[:current_entity]
    @meeting = Meeting.new(:entity_id=>(@entity ? @entity.id : nil), :taken_place_on=>params[:taken_place_on]||Date.today)
    @meeting.employee = @current_user.employee
    if request.post?
      @meeting = Meeting.new(params[:meeting])
      @meeting.company_id = @current_company.id
      redirect_to_back if @meeting.save
    end
    render_form
  end
  
  def meetings_update
    @meeting = find_and_check(:meeting, params[:id])
    if request.post?
      redirect_to_back if @meeting.update_attributes(params[:meeting])
    end
    @title = {:value=>@meeting.entity.full_name}
    render_form
  end
  
  def meetings_delete
    @meeting = find_and_check(:meeting, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @meeting.destroy
    end
  end

end
