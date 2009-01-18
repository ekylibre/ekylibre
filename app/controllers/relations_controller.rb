class RelationsController < ApplicationController

  def index
  end

  dyta(:entities, :conditions=>:search_conditions) do |t|
    t.column :name
    t.column :code
    t.column :full_name
    t.column :active
    t.action :entities_display, :action=>:entities_display
    t.action :entities_update, :image=>:update
    t.action :entities_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :entities_create
  end

  def entities
    @size = Entity.count
    @key = params[:key]||session[:entity_key]
    session[:entity_key] = @key
    entities_list({:attributes=>[:id, :name, :code, :full_name, :website], :key=>@key}.merge(params))
#     #    contacts_list({:attributes=>[:id, :name, :description, :catalog_name, :catalog_description, :comment], :key=>@key}.merge(params))
#     #  entities_list params
#     @entities = {}
#     @contacts = {}
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

#     if @entities.size > 80
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

  def entities_display
    access :contacts
    @company = @current_company
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
    session[:current_entity] = @entity.id
    contacts_list params
    @contact = Contact.new
  end
  
  dyta(:contacts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
    t.column :active
    t.column :default
    t.column :mobile
    t.column :fax
    t.action :entities_contact_update , :image=>:update ,:method=>:post, :remote=> true 
    t.action :entities_contact_delete , :image=>:delete , :method=>:post, :remote=> true, :confirm=>:are_you_sure
  end
  
  def entities_contact_create
    
    if request.post?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      @contact.norm = @current_company.address_norms[0]
      @contact.entity_id = @entity.id
      if @contact
        if request.xhr?
          render :action => "entities_contact_create.rjs"
        else
          redirect_to :action=>:entities_display, :id=>@entity.id if @contact.save
        end
      else
        if request.xhr?
          redirect_to :action=>:entities_contact_create , :id=>@entity.id
        else
          redirect_to :action=>:entities_contact_create , :id=>@entity.id
        end
      end
    end
  end

  def entities_contact_update
    if request.post?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.find_by_id_and_entity_id(params[:id], session[:current_entity])
      if request.xhr?
        render :action => "entities_contact_update.rjs"
      else
        redirect_to :action =>:entities_display, :id=>@entity.id if @contact.update_attributes(params[:contact])
      end
    end
  end
  
  def entities_contact_delete
    if request.post? or request.delete?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      if request.xhr?  
        render :action => "entities_contact_delete.rjs"
      else
        Contact.delete(params[:id]) if @contact
        redirect_to :action => :entities_display, :id=>@entity.id
      end
    end
  end

  def entities_create # pr langage_id prendre current_user.language_id ? puis sortir du _form
    access :entities                      #ou params[:user][:language_id]  // pareil pr nature_id
    if request.post?
      @entity = Entity.new(params[:entity])
      session[:current_entity] = @entity.id
      @entity.company_id = @current_company.id
      # @entity.language_id = @current_company.language.id
      redirect_to :action=>:entities if @entity.save
    else
      @entity = Entity.new
    end
    render_form
  end

 def entities_update
   access :entities
   @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
   if request.post? and @entity
     if @entity.update_attributes(params[:entity])
       redirect_to :action=>:entities
     end
   end
   render_form
 end

 def entities_delete
   access :entities
   if request.post? or request.delete?
     @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
     Entity.delete(params[:id]) if @entity
   end
   redirect_to :action=>:entities
 end

end
