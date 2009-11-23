class ProductionController < ApplicationController

  def index
    @shape_operations = @current_company.shape_operations.find(:all, :conditions=>{:moved_on=>nil})
    #raise Exception.new @shape_operations.inspect
  end

 
  dyta(:tools,  :conditions=>{:company_id=>['@current_company.id']}, :order=>"name desc") do |t|
    t.column :name, :url=>{:action=>:tool}
    t.column :text_nature
    t.column :consumption
    t.action :tool_update
    t.action :tool_delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.uses.size == 0'
  end

  def tools
  end

  dyta(:tool_shape_operations, :model=>:tool_uses, :conditions=>{:company_id=>['@current_company.id'], :tool_id=>['session[:current_tool]']}, :order=>"created_at ASC") do |t|
    t.column :name, :through=>:shape_operation, :url=>{:action=>:shape_operation}, :label=>tc(:name)
    t.column :planned_on, :through=>:shape_operation, :url=>{:action=>:shape_operation}, :label=>tc(:planned_on)
    t.column :moved_on, :through=>:shape_operation, :url=>{:action=>:shape_operation}, :label=>tc(:moved_on)
    t.column :tools_list, :through=>:shape_operation, :url=>{:action=>:shape_operation}, :label=>tc(:tools_list)
    t.column :duration, :through=>:shape_operation, :url=>{:action=>:shape_operation}, :label=>tc(:duration)
  end
  
  def tool
    return unless @tool = find_and_check(:tools, params[:id])
    session[:current_tool] = @tool.id
    @title = {:name=>@tool.name}
  end
  
  manage :tools

  dyta(:productions, :conditions=>{:company_id=>['@current_company.id']}, :order=>"planned_on ASC") do |t|
    t.column :name, :through=>:product, :url=>{:controller=>:management, :action=>:product}
    t.column :quantity
    #t.column :label, :through=>[:product,:unit]
    t.column :moved_on
    t.action :production_update, :image=>:update
    t.action :production_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def productions
  end
  

  def production_create
    if @current_company.stock_locations.empty?
      flash[:warning]=tc(:need_stock_location_to_create_production)
      redirect_to :controller=>:management, :action=>:stock_location_create
    end
    @production = Production.new

    @productable_products = @current_company.productable_products
    
    if request.post?
      @production = Production.new(params[:production])
      @production.company_id = @current_company.id
      if @production.save
        if @production.product.has_components
          redirect_to :action=>:production_line_create, :id=>@production.id
        else
          @production.move_stocks
          redirect_to :action=>:productions 
        end
      end
    end
    render_form
  end

  def production_update
    @production = find_and_check(:production,(params[:id]))
    if request.post?
      if @production.update_attributes(params[:production])
        if @production.product.has_components
          redirect_to :action=>:production_line_update, :id=>@production.id
        else
          redirect_to :action=>:productions
        end
      end
    end
    @title = {:value=>@production.product.name, :moved=>@production.moved_on}
    render_form
  end

  def production_delete
    @production = find_and_check(:production,(params[:id]))   
    if request.delete? or request.post?
      redirect_to :action=>:productions if @production.destroy
    end
  end

  def production_line_create
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

  def production_line_update
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

  # def test_svg()
   # response.headers['Content-type'] = 'text/xml; charset=utf-8'
   # @path = "310 200"
  # end

  
  dyta(:shapes, :conditions=>{:company_id=>['@current_company.id']}, :order=>"name") do |t|
    t.column :name, :url=>{:action=>:shape}
    t.column :polygon
    t.column :description
    t.action :shape_update
    t.action :shape_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  dyta(:operations, :model=>:shape_operations, :conditions=>{:company_id=>['@current_company.id'], :shape_id=>['session[:current_shape]']}, :order=>"planned_on ASC") do |t|
    t.column :name, :url=>{:action=>:shape_operation}
    t.column :name, :through=>:nature
    t.column :full_name, :through=>:employee, :url=>{:controller=>:resources, :action=>:employee}
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :duration
    t.action :shape_operation_update, :image=>:update
    t.action :shape_operation_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
  end

  def shapes
  end

  def shape
    return unless @shape = find_and_check(:shapes, params[:id])
    session[:current_shape] = @shape.id
    @title = {:name=>@shape.name}
  end

  manage :shapes
  
  dyta(:shape_operations, :conditions=>{:company_id=>['@current_company.id']}, :order=>" planned_on desc, name asc") do |t|
    t.column :name, :url=>{:action=>:shape_operation}
    t.column :name, :through=>:nature
    t.column :full_name, :through=>:employee, :url=>{:controller=>:resources, :action=>:employee}
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :name, :through=>:shape, :url=>{:action=>:shape}
    t.column :duration
    t.action :shape_operation_update, :image=>:update
    t.action :shape_operation_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
  end

  def shape_operations
  end

  def shape_operation
    return unless @shape_operation = find_and_check(:shape_operation, params[:id])
    @title = {:name=>@shape_operation.name}
  end
  
  def shape_operation_create
    if request.post?
      @shape_operation = ShapeOperation.new(params[:shape_operation])
      @shape_operation.company_id = @current_company.id
      if @shape_operation.save
        @shape_operation.add_tools(params[:tools])
        redirect_to_back
      end
    else
      @shape_operation = ShapeOperation.new(:planned_on=>Date.today, :employee_id=>@current_user.employee_id)
    end
    render_form
  end

  def shape_operation_update
    return unless @shape_operation = find_and_check(:shape_operations, params[:id])
    session[:tool_ids] = []
    for tool in @shape_operation.tools
      session[:tool_ids] << tool.id.to_s
    end
    if request.post?
      if @shape_operation.update_attributes(params[:shape_operation])
        @shape_operation.add_tools(params[:tools])
        redirect_to_back
      end
    end
    @title = {:name=>@shape_operation.name}
    render_form
  end

  def shape_operation_delete
    return unless @shape_operation = find_and_check(:shape_operations, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @shape_operation.destroy
    end
  end


  dyta(:shape_operation_natures, :conditions=>{:company_id=>['@current_company.id']}, :order=>"name" ) do |t|
    t.column :name
    t.column :description
    t.action :shape_operation_nature_update
    t.action :shape_operation_nature_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def shape_operation_natures
  end

  manage :shape_operation_natures



  dyta(:unvalidated_operations, :model=>:shape_operations, :conditions=>{:moved_on=>nil, :company_id=>['@current_company.id']}) do |t|
    t.column :name 
    t.column :name, :through=>:nature
    t.column :full_name, :through=>:employee, :url=>{:controller=>:resources, :action=>:employee}
    t.column :name, :through=>:shape
    t.column :planned_on
    t.check :validated, :value=>'RECORD.planned_on<=Date.today'
  end

  def unvalidated_operations
    @shape_operations = @current_company.shape_operations.find(:all, :conditions=>{:moved_on=>nil})
    if request.post?
      for id, values in params[:unvalidated_operations]
        operation = ShapeOperation.find_by_id_and_company_id(id, @current_company.id)
        operation.update_attributes!(:moved_on=>Date.today) if operation and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidated_operations
    end
  end


end
