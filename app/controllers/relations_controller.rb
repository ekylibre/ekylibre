class RelationsController < ApplicationController

  def index
  end

  dyta(:entities, :conditions=>:search_conditions) do |t|
    t.column :first_name
    t.column :name
    t.column :full_name
    t.column :code
    t.column :born_on
    t.column :dead_on
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

   dyta(:contacts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['@entity.id']}) do |t|
#   dyta(:contacts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
#   dyta(:contacts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :active
    t.column :default
    t.column :mobile
    t.column :fax
    t.column :phone
    t.column :email 
    t.column :latitude
    t.column :longitude
    t.column :line_2
    t.column :line_3
    t.column :line_4_number
    t.column :line_5
    t.action :entities_contacts_update , :image=>:update 
    t.action :entities_contacts_delete , :image=>:delete , :method=>:post, :confirm=>'are_you_sure'
   # t.procedure :entities_contacts_create 
  end

  def entities_display
    if request.get?
      @company = @current_company
      @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
      session[:current_entity] = @entity.id
      #raise Exception.new session[:current_entity].inspect
      @name = @entity.first_name.to_s+" "+@entity.name.to_s
      contacts_list params
      session[:my_entity] = params[:id]
      @id = params[:id]
      @contact = Contact.new
      session[:current_entity] = params[:id]
    end
    session[:current_entity] = params[:id]
  end
  
  
  def entities_contacts_create
    @contact = Contact.new(params[:contact])
    @id = params[:id] # @id = session[:my_entity]
    #session[:current_entity] = params[:id]
    #raise Exception.new @id.inspect+ "ezze"
    if request.post?
      @entity = Entity.find_by_id_and_company_id(@id, @current_company.id)
      #raise Exception.new @entity.inspect
      @contact.company_id = @current_company.id
      @contact.norm = @current_company.address_norms[0]
      @contact.entity_id = @entity.id  
      redirect_to :action=>:entities_display, :id=>@entity.id if @contact.save
    end
    render_form
  end

  def entities_contacts_update
    access :contacts
    @entity = Entity.find_by_id_and_company_id(session[:current_entity], @current_company.id)
    #raise Exception.new @entity.inspect
    # @contact = Contact.find_by_id_and_entity_id(params[:id], session[:current_entity])
    @contact = Contact.find_by_id_and_company_id(params[:id], @current_company.id)
    if request.post? and @contact
      redirect_to_back if @contact.update_attributes(params[:contact])
     # redirect_to :action=>:entities_display, :id=>@entity.id  if @contact.update_attributes(params[:contact])
    end
    render_form
  end
  
  def entities_contacts_delete
    access :contacts
    if request.post? or request.delete?
     # @entity = Entity.find_by_id_and_company_id(session[:current_entity], @current_company.id)
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      Contact.delete(@contact) if @contact
     # redirect_to :action => :entities_display, :id=>@entity.id
    end
    redirect_to_back
  end
  
  def entities_create
    access :entities                      
    if request.post?
      @entity = Entity.new(params[:entity])
      @entity.company_id = @current_company.id
      # @entity.dead_on = Date.new(params[:entity][:dead_on])
      if @entity.save
        redirect_to :action=>:entities
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
   render_form(:label=>@entity.name+" "+@entity.first_name)
 end

 def entities_delete
   access :entities
   if request.post? or request.delete?
     @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
     @id = params[:id]
     Entity.delete(@id) if @entity
   end
   redirect_to :action=>:entities
 end

end
