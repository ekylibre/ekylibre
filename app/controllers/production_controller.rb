class ProductionController < ApplicationController

  def index
    @shape_operations = @current_company.shape_operations.find(:all, :conditions=>{:moved_on=>nil})
    #raise Exception.new @shape_operations.inspect
  end


  dyta(:productions, :conditions=>{:company_id=>['@current_company.id']} ) do |t|
    t.column :name, :through=>:product
    t.column :quantity
    #t.column :label, :through=>[:product,:unit]
    t.column :moved_on
    t.action :productions_update, :image=>:update
    t.action :productions_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def productions
    productions_list 
  end
  

  def productions_create
    if @current_company.stock_locations.empty?
      flash[:warning]=tc(:need_stock_location_to_create_production)
      redirect_to :controller=>:management, :action=>:stocks_locations_create
    end
    @production = Production.new

    @productable_products = @current_company.productable_products
   
    if request.post?
      @production = Production.new(params[:production])
      @production.company_id = @current_company.id
      if @production.save
        if @production.product.has_components
          redirect_to :action=>:production_lines_create, :id=>@production.id
        else
          @production.move_stocks
          redirect_to :action=>:productions 
        end
      end
    end
    render_form
  end

  def productions_update
    @production = find_and_check(:production,(params[:id]))
    if request.post?
      if @production.update_attributes(params[:production])
        if @production.product.has_components
          redirect_to :action=>:production_lines_update, :id=>@production.id
        else
          redirect_to :action=>:productions
        end
      end
    end
    @title = {:value=>@production.product.name, :moved=>@production.moved_on}
    render_form
  end

  def productions_delete
    @production = find_and_check(:production,(params[:id]))   
    if request.delete? or request.post?
      redirect_to :action=>:productions if @production.destroy
    end
  end

  def production_lines_create
    @production = find_and_check(:production, params[:id])
    @components = @production.product.components    
    if request.post?
      quantities_mistake = false
      for component in @components
        quantities_mistake = true if !component.check_quantities(params[:component],@production.quantity)
      end
      if quantities_mistake
        @production.errors.add_to_base(tc('mistake_on_quantities_sum'))
      else
        @production.move_stocks(params[:component])
        redirect_to :action=>:productions
      end
    end
    render_form
  end

  def production_lines_update
    @production = find_and_check(:production, params[:id])
    @components = @production.product.components   
    if request.post?
      quantities_mistake = false
      for component in @components
        quantities_mistake = true if !component.check_quantities(params[:component],@production.quantity)
      end
      if quantities_mistake
        @production.errors.add_to_base(tc('mistake_on_quantities_sum'))
      else
        @production.move_stocks(params[:component], update=true)
        redirect_to :action=>:productions
      end
    end
    render_form
  end

  def test_svg
    response.headers['Content-type'] = 'text/xml; charset=utf-8'
    @path = "310 200"
  end

  
  dyta(:shapes, :conditions=>{:company_id=>['@current_company.id']} ) do |t|
    t.column :name
    t.column :polygon
  end

  dyta(:shape_operations, :conditions=>{:company_id=>['@current_company.id']} ) do |t|
    t.column :name
    t.column :name, :through=>:nature
    t.column :last_name, :through=>:employee
    t.column :planned_on
    t.column :name, :through=>:shape
    t.action :shape_operations_update, :image=>:update
    t.action :shape_operations_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
  end

  dyta(:shape_operation_natures, :conditions=>{:company_id=>['@current_company.id']} ) do |t|
    t.column :name
    t.column :description
  end

  def shapes
    shapes_list
  end

  def shapes_create
    @shape = Shape.new
    if request.post?
      @shape = Shape.new(params[:shape])
      @shape.company_id = @current_company.id
      redirect_to_back if @shape.save
    end
    render_form
  end
  
  def shape_operations
    shape_operations_list
  end

  def shape_operations_create
    @shape_operation = ShapeOperation.new(:planned_on=>Date.today)
    if request.post?
      @shape_operation = ShapeOperation.new(params[:shape_operation])
      @shape_operation.company_id = @current_company.id
      redirect_to_back if @shape_operation.save
    end
    render_form
  end

  def shape_operations_update
    @shape_operation = find_and_check(:shape_operation, params[:id])
    if request.post?
      redirect_to_back if @shape_operation.update_attributes(params[:shape_operation])
    end
    @title = {:value=>@shape_operation.name}
    render_form
  end
  
  def shape_operations_delete
    @shape_operation = find_and_check(:shape_operation, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @shape_operation.destroy
    end
  end

  def shape_operation_natures
    shape_operation_natures_list
  end

  def shape_operation_natures_create
    @shape_operation_nature = ShapeOperationNature.new
    if request.post?
      @shape_operation_nature = ShapeOperationNature.new(params[:shape_operation_nature])
      @shape_operation_nature.company_id = @current_company.id 
      redirect_to_back if @shape_operation_nature.save
    end
    render_form
  end

  def unvalidated_operations
    @shape_operations = @current_company.shape_operations.find(:all, :conditions=>{:moved_on=>nil})
  end


end
