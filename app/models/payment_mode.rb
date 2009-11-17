# == Schema Information
#
# Table name: payment_modes
#
#  account_id      :integer       
#  bank_account_id :integer       
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  creator_id      :integer       
#  id              :integer       not null, primary key
#  lock_version    :integer       default(0), not null
#  mode            :string(5)     
#  name            :string(50)    not null
#  nature          :string(1)     default("U"), not null
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

class PaymentMode < ActiveRecord::Base
  belongs_to :account
  belongs_to :bank_account
  belongs_to :company
  has_many :entities
  has_many :payments, :foreign_key=>:mode_id
  has_many :embankable_payments, :class_name=>Payment.name, :foreign_key=>:mode_id, :conditions=>["embankment_id IS NULL"]
  attr_readonly :company_id
  @@modes = [:card, :cash, :check, :other, :transfer] 

  #validates_presence_of :account_id

  def self.modes
    @@modes.collect{|x| [tc('modes.'+x.to_s), x]}
  end

end
