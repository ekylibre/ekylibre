class ProductionController < ApplicationController

  def index
  end


  dyta(:productions, :conditions=>{:company_id=>['@current_company.id']} ) do |t|
    t.column :name, :through=>:product
    t.column :quantity
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
          @production.single_stock_move_create
          redirect_to :action=>:productions 
        end
      end
    end
    render_form
  end

  def 

  def productions_update
  end

  def productions_delete
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
        @production.stocks_moves_create(params[:component])
        redirect_to :action=>:productions
      end
    end
    render_form
  end


end
