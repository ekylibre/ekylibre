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
# == Table: tax_declarations
#
#  accounted_at             :datetime         
#  acquisition_amount       :decimal(16, 2)   
#  address                  :string(255)      
#  amount                   :decimal(16, 2)   
#  assimilated_taxes_amount :decimal(16, 2)   
#  balance_amount           :decimal(16, 2)   
#  collected_amount         :decimal(16, 2)   
#  company_id               :integer          not null
#  created_at               :datetime         not null
#  creator_id               :integer          
#  declared_on              :date             
#  deferred_payment         :boolean          
#  financial_year_id        :integer          
#  id                       :integer          not null, primary key
#  journal_entry_id         :integer          
#  lock_version             :integer          default(0), not null
#  nature                   :string(255)      default("normal"), not null
#  paid_amount              :decimal(16, 2)   
#  paid_on                  :date             
#  started_on               :date             
#  stopped_on               :date             
#  updated_at               :datetime         not null
#  updater_id               :integer          
#


class TaxDeclaration < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :acquisition_amount, :amount, :assimilated_taxes_amount, :balance_amount, :collected_amount, :paid_amount, :allow_nil => true
  validates_length_of :address, :nature, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :company
  belongs_to :financial_year


  NB_DAYS_MONTH=30.42

  #
  def x_clean
    # raise Exception.new('salut')
    #if self.started_on.blank?

    #      last_declaration = self.company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on")
    #      if last_declaration.nil?
    #        self.nature = "normal"
    #        self.started_on = Date.today.beginning_of_month
    #        self.stopped_on = Date.today.end_of_month
    #      else
    #        self.nature = last_declaration.nature
    #        self.started_on = last_declaration.stopped_on + 1
    
    #        nb_months = ((last_declaration.stopped_on - last_declaration.started_on)/NB_DAYS_MONTH).round 
    
    #        if nb_months == 1
    #          self.stopped_on = self.started_on.end_of_month
    #        elsif nb_months == 3
    #          self.stopped_on = self.started_on.months_since 3.end_of_month
    #        elsif nb_months == 12
    #          self.stopped_on = self.started_on.months_since 12.end_of_month
    #        end
    #      end
    
    #end

  end

  # this method allows to verify the different characteristics of the tax declaration.
  validate do
    errors.add_to_base(:one_data_to_record_tax_declaration)  if self.collected_amount.zero? and self.acquisition_amount.zero? and self.assimilated_taxes_amount.zero? and self.paid_amount.zero? and self.balance_amount.zero?
    errors.add(:started_on, :overlapped_period_declaration) if self.company.tax_declarations.find(:first, :conditions=>["? BETWEEN started_on AND stopped_on", self.started_on]) 
    errors.add(:stopped_on, :overlapped_period_declaration) if self.company.tax_declarations.find(:first, :conditions=>["? BETWEEN started_on AND stopped_on", self.started_on]) 
    unless self.financial_year.nil?
      errors.add(:declared_on, :declaration_date_after_period) if self.declared_on < self.financial_year.stopped_on 
    end
  end

  # this method allows to comptabilize the tax declaration after it creation. 
  bookkeep(:on=>:nothing) do |b|
  end


  
  #
  def x_before_create
    #    if self.started_on.blank?
    #      last_declaration = self.company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on")
    #      if last_declaration.nil?
    #        self.nature = "normal"
    #        self.started_on = Date.today.beginning_of_month
    #        self.stopped_on = Date.today.end_of_month
    #      else
    #        self.nature = last_declaration.nature
    #        self.started_on = last_declaration.stopped_on + 1
    
    #        nb_months = ((last_declaration.stopped_on - last_declaration.started_on)/NB_DAYS_MONTH).round 
    
    #        if nb_months == 1
    #          self.stopped_on = self.started_on.end_of_month
    #        elsif nb_months == 3
    #          self.stopped_on = self.started_on.months_since 3.end_of_month
    #        elsif nb_months == 12
    #          self.stopped_on = self.started_on.months_since 12.end_of_month
    #        end
    #      end
    #    end
  end



  #
  def self.credits
    [:deferment, :payback].collect{|x| [tc(x.to_s), x] }
  end

  #
  def self.natures
    [:normal, :simplified].collect{|x| [tc(x.to_s), x] }
  end

  #
  def self.periods
    [:other, :monthly, :quarterly, :yearly].collect{|x| [tc(x.to_s), x] }
  end

  #virtual method.
  def period=
  end

  #
  def period
    nb_months = ((self.stopped_on - self.started_on)/NB_DAYS_MONTH).round
    
    if nb_months == 1
      return :monthly
    elsif nb_months == 3
      return :quarterly
    elsif nb_months == 12
      return :yearly
    else
      return :other
    end
  end

end
