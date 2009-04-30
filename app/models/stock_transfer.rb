class StockTransfer < ActiveRecord::Base

  belongs_to :company
  belongs_to :product
  belongs_to :location, :class_name=>StockLocation.to_s
  belongs_to :second_location, :class_name=>StockLocation.to_s

  attr_readonly :company_id


  def before_create
  end
  
  def before_update
  end

  def before_destroy
  end
  
  def self.natures
    [:transfer, :waste].collect{|x| [tc('natures.'+x.to_s), x] }
  end


end
