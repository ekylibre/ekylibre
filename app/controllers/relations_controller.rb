class RelationsController < ApplicationController

  def index
  end

  dyta(:entities, :conditions=>:search_conditions, :empty=>true) do |t|
    t.column :name, :url=>{:action=>:entities_display}
    t.column :first_name, :url=>{:action=>:entities_display}
    #    t.column :full_name
    t.column :code, :url=>{:action=>:entities_display}
    t.column :born_on
    #    t.column :dead_on
    t.column :website
    t.column :active
    t.action :entities_display, :image=>:show
    t.action :entities_update, :image=>:update
    t.action :entities_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :entities_create
  end


  
  def entities
    @size = Entity.count
    @key = params[:key]||session[:entity_key]
    session[:entity_key] = @key
    entities_list({:attributes=>[:id, :name, :code, :full_name, :website], :key=>@key}.merge(params))
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

  dyta(:contacts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['@entity.id'], :deleted=>false}, :empty=>true) do |t|
    t.column :name, :url=>{:action=>:entities_contacts_update}
    t.column :address, :url=>{:action=>:entities_contacts_update}
    t.column :phone
    t.column :fax
    t.column :mobile
    t.column :email
    t.column :website
    t.column :default
    t.action :entities_contacts_update , :image=>:update 
    t.action :entities_contacts_delete , :image=>:delete , :method=>:post, :confirm=>'are_you_sure'
    t.procedure :entities_contacts_create
  end

  def entities_display
    @company = @current_company
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
    session[:current_entity] = @entity.id
    @name = @entity.first_name.to_s+" "+@entity.name.to_s
    contacts_list params
    session[:my_entity] = params[:id]
    @id = params[:id]
    @contact = Contact.new
    session[:current_entity] = params[:id]
    @title = {:value=>@entity.full_name}
  end
  
  def entities_create
    access :entities                      
    if request.post?
      @entity = Entity.new(params[:entity])
      @entity.company_id = @current_company.id
      if @entity.save
        redirect_to_back
#        redirect_to :action=>:entities_display, :id=>@entity.id
      end
    else
      @entity = Entity.new
    end
    render_form
  end
  
  def entities_update
    access :entities
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @entity
      redirect_to :action=>:entities if @entity.update_attributes(params[:entity])
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
      @contact.name = (@entity.contacts.size>0 ? tc(:second_contact) : tc(:first_contact) )
    end
    @title = {:value=>@entity.full_name}
    render_form
  end

  def entities_contacts_update
    access :contacts
    @entity = Entity.find_by_id_and_company_id(session[:current_entity], @current_company.id)
    @contact = Contact.find_by_id_and_company_id(params[:id], @current_company.id)
    @id = @contact.entity_id
    if request.post? and @contact
      redirect_to_back if @contact.update_attributes(params[:contact])
    end
    @title = {:entity=>@entity.full_name, :contact=>@contact.name}
    render_form
  end
  
  def entities_contacts_delete
    access :contacts
    if request.post? or request.delete?
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      @id = @contact.entity_id
      @contact.deleted = true
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




  
end
