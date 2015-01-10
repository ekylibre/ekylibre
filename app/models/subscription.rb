# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: subscriptions
#
#  comment      :text             
#  company_id   :integer          not null
#  contact_id   :integer          
#  created_at   :datetime         not null
#  creator_id   :integer          
#  entity_id    :integer          
#  first_number :integer          
#  id           :integer          not null, primary key
#  last_number  :integer          
#  lock_version :integer          default(0), not null
#  nature_id    :integer          
#  number       :string(255)      
#  product_id   :integer          
#  quantity     :decimal(16, 4)   
#  sale_id      :integer          
#  sale_line_id :integer          
#  started_on   :date             
#  stopped_on   :date             
#  suspended    :boolean          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Subscription < CompanyRecord
  acts_as_numbered
  attr_readonly :company_id
  belongs_to :company
  belongs_to :contact
  belongs_to :entity
  belongs_to :nature, :class_name=>"SubscriptionNature"
  belongs_to :product
  belongs_to :sale
  belongs_to :sale_line 
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :first_number, :last_number, :allow_nil => true, :only_integer => true
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :suspended, :in => [true, false]
  validates_presence_of :company
  #]VALIDATORS]
  validates_presence_of :started_on, :stopped_on, :if=>Proc.new{|u| u.nature and u.nature.nature=="period"}
  validates_presence_of :first_number, :last_number, :if=>Proc.new{|u| u.nature and u.nature.nature=="quantity"}
  validates_presence_of :nature, :entity
  validates_presence_of :sale_line, :if=>Proc.new{|s| !s.sale.nil?}, :on=>:create

  before_validation do
    self.contact   ||= self.sale.delivery_contact if self.sale
    self.entity_id = self.contact.entity_id if self.contact
    self.nature_id ||= self.product.subscription_nature_id if self.product
    self.sale_id ||= self.sale_line.sale_id if self.sale_line
    return true
  end

  before_validation(:on=>:create) do
    if self.nature
      if self.nature.nature == "period"
        if self.product
          period = (self.product.subscription_period.blank? ? '1 year' : self.product.subscription_period)||'1 year'
        else
          period = '1 year'
        end
        #raise Exception.new "ok"+period.inspect+self.product.subscription_period.inspect
        self.started_on ||= Date.today
        self.stopped_on ||= Delay.compute(period+", 1 day ago", self.started_on)
      else
        if self.product
          period = (self.product.subscription_quantity.blank? ? 1 : self.product.subscription_quantity)||1
        else
          period = 1
        end
        self.first_number ||= self.nature.actual_number
        self.last_number  ||= self.first_number+period-1
      end
    end
  end

  validate do
    if self.contact and self.entity
      errors.add(:entity_id, :entity_must_be_the_same_as_the_contact_entity) if self.contact.entity_id!=self.entity_id
    end
  end
  

  def entity_name
    if self.entity
      self.entity.full_name
    elsif self.contact
      if self.contact.entity.is_a?(Entity)
        self.contact.entity.full_name
      else
        '--'
      end
    else
      '-'
    end
  end

  # Initialize default preferences
  def compute_period
    #self.clean
    if self.product
      self.nature_id ||= self.product.subscription_nature_id 
      self.company_id ||= self.product.company_id
    end
    self.company_id ||= self.nature.company_id if self.nature
    self.valid? if self.new_record?
    self
  end

  # TODO: Change method name
#  def natura
#    self.nature||(self.product ? self.product.subscription_nature : 'unknown_nature')
#  end

  def start
    if self.nature.nature == "quantity"
      self.first_number
    elsif self.started_on.nil?
      ''
    else
      ::I18n.localize(self.started_on)
    end
  end

  def finish
    if self.nature.nature == "quantity"
      self.last_number
    elsif self.stopped_on.nil?
      ''
    else
      ::I18n.localize(self.stopped_on)
    end
  end

  def active?(instant=nil)
    if self.nature.nature == "quantity"
      instant ||= self.nature.actual_number
      self.first_number<=instant and instant<=self.last_number
    else
      instant ||= Date.today
      self.started_on<=instant and instant<=self.stopped_on
    end
  end


end
