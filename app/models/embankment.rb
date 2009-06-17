class Embankment < ActiveRecord::Base


  belongs_to :bank_account
  belongs_to :company
  belongs_to :mode, :class_name=>PaymentMode.to_s
  has_many :payments

  attr_readonly :company_id

  def before_validation
    if !self.id.nil?
      payments = Payment.find_all_by_company_id_and_embankment_id(self.company_id, self.id)
      # raise Exception.new self.inspect+"                      "+payments.inspect
      self.payments_number = payments.size
      self.amount = payments.sum{|p| p.amount}
    end
  end

  
  def before_destroy
    #raise Exception.new self.checks.inspect
    for check in self.checks
      check.update_attributes(:embankment_id=>nil)
    end
  end


  def refresh
    self.save
  end

  def checks
    Payment.find_all_by_company_id_and_embankment_id(self.company_id, self.id)
  end


end
