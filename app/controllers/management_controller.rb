class ManagementController < ApplicationController

  def index
  end

  def sales
  end

  # Step 1
  def sales_new
    @step = 1
    session[:sales] = {}
    session[:sales][:nature]    = params[:nature]
    session[:sales][:entity_id] = params[:client]
    session[:sales] = params[:sales] if params[:sales].is_a? Hash
    if session[:sales][:entity_id]
      entity = Entity.find_by_company_id_and_id(session[:sales][:entity_id], @current_company.id)
      session[:sales].delete(:entity_id) if entity.nil?
    end
    if request.get?
      unless session[:sales][:nature].nil? or session[:sales][:entity_id].nil?
        redirect_to :action=>:sales_general
      end
    end
  end

  # Step 2
  def sales_general
    @step = 2
  end

  # Step 3
  def sales_products
    @step = 3
  end

  # Step 4
  def sales_deliveries
    @step = 4
  end

  # Step 5
  def sales_invoices
    @step = 5
  end

  # Step 6
  def sales_payments
    @step = 6
  end

  # Step 7
  def sales_print
    @step = 7
  end
  

  
  def purchases
  end

  def stocks
  end

end
