class RelationsController < ApplicationController

  def index
    @company = @current_company
    @entities = @company.entities
  end

  dyta(:entities, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :full_name
    t.column :active
    t.action :entities_display, :action=>:entities_display
    t.action :entities_update, :image=>:update
    t.action :entities_delete, :image=>:delete, :method=>:post, :confirm=>:sure
  end

  def entities
    entities_list params
  end

  def entities_search
  end

  dyta(:contacts, :conditions=>{:company_id=>['@current_company.id']}) do |t| # element_id=>[@entity.id]entity
    t.column :active
    t.column :default
    t.column :mobile
    t.column :fax
    t.action :entities_contact_update , :image=>:update
    t.action :entities_contact_delete , :image=>:delete , :method=>:post, :confirm=>:sure
  end
  
  def entities_display
    access :contacts
    @company = @current_company
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
    contacts_list params
    @contact = Contact.new
    session[:current_entity] = @entity.id
    #render  :action=>:entities_contact_create
  end
  
  def entities_contact_create
    
    if request.post?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      # @contact.element = @entity
      @contact.norm = @current_company.address_norms[0]
      #raise Exception.new @entity.attributes.to_s
      #raise Exception.new @contact.attributes.to_s
      @contact.entity_id = @entity.id
      if @contact
        if request.xhr?
          render :action => "entities_contact_create.rjs"
        else
          redirect_to :action=>:entities_display, :id=>@entity.id if @contact.save
          #render :action => :entities_display
        end
        # rafraichir tab
      else
        if request.xhr?
          redirect_to :action=>:entities
        else
          #raise Exception.new "jdjdj"
          redirect_to :action=>:entities
          # params[:id]= @entity.id
          # entities_display
          # render :action=>:entities_display
        end
        # rafraichir form
      end
    end
  end

  def entities_contact_update
    if request.post?
      # @contact = Contact.find_by_id_and_en
      if request.xhr?
        render :action => " entities_contact_update.rjs"
      end
    end
  end

  def entities_contact_delete
    @entity = Entity.find(session[:current_entity])
    #raise Exception.new "eghegh"
    if request.post? or request.delete?
      #raise Exception.new "dehjehjehjeh"
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      Contact.delete(params[:id]) if @contact
      #raise Exception.new "dehjehjehjeh"
    end
    
    redirect_to :action=>:entities_display , :id=>@entity.id
  end
  

  def entities_create # pr langage_id prendre current_user.language_id ? puis sortir du _form
    access :entities                      #ou params[:user][:language_id]  // pareil pr nature_id
    if request.post?
      @entity = Entity.new(params[:entity])
      @entity.company_id = @current_company.id
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
