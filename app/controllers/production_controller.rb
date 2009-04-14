class ProductionController < ApplicationController

  def index
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

    @productable_products = @current_company.products.find_by_sql ["SELECT * FROM products WHERE (supply_method = 'produce' OR id IN (SELECT product_id FROM product_components WHERE company_id = ?))", @current_company.id]

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


end
