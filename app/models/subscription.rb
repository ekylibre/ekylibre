class Subscription < ActiveRecord::Base



  belongs_to :company
  belongs_to :product
  #belongs_to :sale_order_line

  validates_presence_of :started_on, :finished_on, :if=>Proc.new{|u| u.product.nature=="sub_date"}


  def before_validation
   
  end


end
