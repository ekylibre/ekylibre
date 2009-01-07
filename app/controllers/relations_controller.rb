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

  dyta(:contacts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :active
  end
  
  def entities_display
    @company = @current_company
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
    contacts_list params
  end

  def entities_create # pr langage_id prendre current_user.language_id ?
    access :entities                      #ou params[:user][:language_id]
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
