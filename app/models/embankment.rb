# == Schema Information
#
# Table name: embankments
#
#  amount          :decimal(16, 4 default(0.0), not null
#  bank_account_id :integer       not null
#  comment         :text          
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  created_on      :date          not null
#  creator_id      :integer       
#  embanker_id     :integer       
#  id              :integer       not null, primary key
#  lock_version    :integer       default(0), not null
#  locked          :boolean       not null
#  mode_id         :integer       not null
#  payments_count  :integer       default(0), not null
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

class Embankment < ActiveRecord::Base
  belongs_to :bank_account
  belongs_to :company
  belongs_to :embanker, :class_name=>User.name
  belongs_to :mode, :class_name=>PaymentMode.to_s
  has_many :payments, :dependent=>:nullify, :order=>"created_at"

  validates_presence_of :embanker_id, :number

  attr_readonly :company_id

  def before_validation
    if !self.id.nil?
      payments = Payment.find_all_by_company_id_and_embankment_id(self.company_id, self.id)
      self.payments_count = payments.size
      self.amount = payments.sum{|p| p.amount}
    end

    specific_numeration = self.company.parameter("management.embankments.numeration")
    if specific_numeration and specific_numeration.value
      self.number = specific_numeration.value.next_value
    else
      last = self.company.embankments.find(:first, :conditions=>["company_id=? AND number IS NOT NULL", self.company_id], :order=>"number desc")
      self.number = last ? last.number.succ : '000000'
    end

  end

  
  def before_destroy
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

  # this method valids the embankment and accountizes the matching payments.
  # def confirm
#     payments = Payment.find_all_by_company_id_and_embankment_id(self.company_id, self.id)
#     payments.each do |payment|
#       payment.to_accountancy
      
#     end
#   end

  
end
