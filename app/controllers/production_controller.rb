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
  
## Check !stockLocations.nil?
  def productions_create
    @productable_products = @current_company.products.find_by_sql ["SELECT * FROM products WHERE (supply_method = 'produce' OR id IN (SELECT product_id FROM product_components WHERE company_id = ?))", @current_company.id]
    @production = Production.new
    if request.post?
      @production = Production.new(params[:production])
      @production.company_id = @current_company.id
      if @production.save
        if @production.product.has_components
          raise Exception.new "ok"
          @production.many_stocks_moves_create
        else
          raise Exception.new "nok"
          @production.single_stock_move_create
        end
        redirect_to :action=>:productions 
      end
    end
    render_form
  end

end
