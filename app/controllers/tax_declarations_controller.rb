# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class TaxDeclarationsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>:declared_on) do |t|
    t.column :nature
    t.column :address
    t.column :declared_on, :datatype=>:date
    t.column :paid_on, :datatype=>:date
    t.column :amount
    t.action :tax_declaration, :image => :show
    t.action :edit #, :if => '!RECORD.submitted?'  
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete #, :if => '!RECORD.submitted?'
  end

  # Displays details of one tax declaration selected with +params[:id]+
  def show
    return unless find_and_check(:tax_declaration)
    
    # last vat declaration for read the excedent VAT
    # if ["simplified"].include? @tax_declaration.nature
    #       started_on = @tax_declaration.started_on.years_ago 1
    #     else
    #       if ["monthly"].include? @tax_declaration.period
    #         started_on = @tax_declaration.started_on.months_ago 1.beginning_of_month
    #       else
    #         started_on = @tax_declaration.started_on.months_ago 3.beginning_of_month
    #       end
    #     end
    #     @last_tax_declaration = @current_company.tax_declarations.find(:last, :conditions=> ["started_on =  ? and stopped_on = ?", started_on, (@tax_declaration.started_on-1)])
    
    
    # datas for vat collected 
    @normal_vat_collected_amount = {}
    @normal_not_collected_amount = {}
    @normal_vat_collected_amount[:national] = @current_company.filtering_entries(:credit, ['445713*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @normal_not_collected_amount[:national] = @current_company.filtering_entries(:credit, ['707003'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    
    @normal_vat_collected_amount[:international] = @current_company.filtering_entries(:credit, ['445714*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @normal_not_collected_amount[:international] = @current_company.filtering_entries(:credit, ['707004'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    @vat_paid_and_payback_amount = @current_company.filtering_entries(:credit, ['445660'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    
    @reduce_vat_collected_amount = {}
    @reduce_not_collected_amount = {}
    @reduce_vat_collected_amount[:national] = @current_company.filtering_entries(:credit, ['445712*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @reduce_not_collected_amount[:national] = @current_company.filtering_entries(:credit, ['707002'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    @reduce_vat_collected_amount[:international] = @current_company.filtering_entries(:credit, ['445711*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @reduce_not_collected_amount[:international] = @current_company.filtering_entries(:credit, ['707001'], [@tax_declaration.started_on, @tax_declaration.stopped_on])



    # assessable operations 
    
    # @vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [@tax_declaration.period_begin, @tax_declaration.period_end]) 
    

    # datas for vat paid.
    @vat_deductible_fixed_amount = @current_company.filtering_entries(:debit, ['445620*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @vat_deductible_services_amount = @current_company.filtering_entries(:debit, ['445660*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @vat_deductible_others_amount = @current_company.filtering_entries(:debit, ['44563*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @vat_deductible_left_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    # downpayment amount
    if ["simplified"].include? @tax_declaration.nature
      @downpayment_amount = @current_company.filtering_entries(:debit, ['44581*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
      
      #  others operations for vat collected
      # @sales_fixed_amount = @current_company.filtering_entries(:credit, ['775*'], [@tax_declaration.period_begin, @period_end])
      # @vat_sales_fixed_amount = @current_company.filtering_entries(:debit, ['44551*'], [@tax_declaration.period_begin, @period_end])

      # @oneself_deliveries_amount = @current_company.filtering_entries(:credit, ['772000*'], [@tax_declaration.period_begin, @period_end])
    end

    # payback of vat credits.
    @vat_payback_amount = @current_company.filtering_entries(:debit, ['44583*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    t3e :nature => tc(@tax_declaration.nature), :started_on => @tax_declaration.started_on, :stopped_on => @tax_declaration.stopped_on
  end

  def new
    
    @financial_years = @current_company.financial_years.find(:all, :conditions => ["closed = 't'"])
    
    unless @financial_years.size > 0
      notify(:need_closed_financial_year_to_declaration)
      redirect_to :action=>:tax_declarations
      return
    end
    
    if request.post?
      started_on = params[:tax_declaration][:started_on]
      stopped_on = params[:tax_declaration][:stopped_on]
      params[:tax_declaration].delete(:period) 
      
      vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [started_on, stopped_on]) 
      vat_collected_amount = @current_company.filtering_entries(:credit, ['44571*'], [started_on, stopped_on]) 
      vat_deductible_amount = @current_company.filtering_entries(:debit, ['4456*'], [started_on, stopped_on]) 
      vat_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [started_on, stopped_on]) 
      vat_assimilated_amount = @current_company.filtering_entries(:credit, ['447*'], [started_on, stopped_on]) 

      journal_od = @current_company.journals.find(:last, :conditions=>["nature = ? and closed_on < ?", :various.to_s, Date.today.to_s])

      #      raise Exception.new(params.inspect)
      @current_company.journals.create!(:nature=>"various", :name=>tc(:various), :currency_id=>@current_company.currencies(:first), :code=>"OD", :closed_on=>Date.today) if journal_od.nil?
      
      
      
      @tax_declaration = TaxDeclaration.new(params[:tax_declaration].merge!({:collected_amount=>vat_collected_amount, :paid_amount=>vat_deductible_amount, :balance_amount=>vat_balance_amount, :assimilated_taxes_amount=>vat_assimilated_amount, :acquisition_amount=>vat_acquisitions_amount, :started_on=>started_on, :stopped_on=>stopped_on}))
      @tax_declaration.company_id = @current_company.id
      return if save_and_redirect(@tax_declaration)
      
    else
      @tax_declaration = TaxDeclaration.new

      if @tax_declaration.new_record?
        last_declaration = @current_company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on, nature")
        if last_declaration.nil?
          @tax_declaration.nature = "normal"
          last_financial_year = @current_company.financial_years.find(:last, :conditions=>{:closed => true})
          @tax_declaration.started_on = last_financial_year.started_on
          @tax_declaration.stopped_on = last_financial_year.started_on.end_of_month
        else
          @tax_declaration.nature = last_declaration.nature
          @tax_declaration.started_on = last_declaration.stopped_on+1
          @tax_declaration.stopped_on = @tax_declaration.started_on+(last_declaration.stopped_on-last_declaration.started_on)-2          
        end
        @tax_declaration.stopped_on = params[:stopped_on].to_s if params.include? :stopped_on and params[:stopped_on].blank?
      end
      
    end       
    
    render_restfully_form
  end

  def create
    
    @financial_years = @current_company.financial_years.find(:all, :conditions => ["closed = 't'"])
    
    unless @financial_years.size > 0
      notify(:need_closed_financial_year_to_declaration)
      redirect_to :action=>:tax_declarations
      return
    end
    
    if request.post?
      started_on = params[:tax_declaration][:started_on]
      stopped_on = params[:tax_declaration][:stopped_on]
      params[:tax_declaration].delete(:period) 
      
      vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [started_on, stopped_on]) 
      vat_collected_amount = @current_company.filtering_entries(:credit, ['44571*'], [started_on, stopped_on]) 
      vat_deductible_amount = @current_company.filtering_entries(:debit, ['4456*'], [started_on, stopped_on]) 
      vat_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [started_on, stopped_on]) 
      vat_assimilated_amount = @current_company.filtering_entries(:credit, ['447*'], [started_on, stopped_on]) 

      journal_od = @current_company.journals.find(:last, :conditions=>["nature = ? and closed_on < ?", :various.to_s, Date.today.to_s])

      #      raise Exception.new(params.inspect)
      @current_company.journals.create!(:nature=>"various", :name=>tc(:various), :currency_id=>@current_company.currencies(:first), :code=>"OD", :closed_on=>Date.today) if journal_od.nil?
      
      
      
      @tax_declaration = TaxDeclaration.new(params[:tax_declaration].merge!({:collected_amount=>vat_collected_amount, :paid_amount=>vat_deductible_amount, :balance_amount=>vat_balance_amount, :assimilated_taxes_amount=>vat_assimilated_amount, :acquisition_amount=>vat_acquisitions_amount, :started_on=>started_on, :stopped_on=>stopped_on}))
      @tax_declaration.company_id = @current_company.id
      return if save_and_redirect(@tax_declaration)
      
    else
      @tax_declaration = TaxDeclaration.new

      if @tax_declaration.new_record?
        last_declaration = @current_company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on, nature")
        if last_declaration.nil?
          @tax_declaration.nature = "normal"
          last_financial_year = @current_company.financial_years.find(:last, :conditions=>{:closed => true})
          @tax_declaration.started_on = last_financial_year.started_on
          @tax_declaration.stopped_on = last_financial_year.started_on.end_of_month
        else
          @tax_declaration.nature = last_declaration.nature
          @tax_declaration.started_on = last_declaration.stopped_on+1
          @tax_declaration.stopped_on = @tax_declaration.started_on+(last_declaration.stopped_on-last_declaration.started_on)-2          
        end
        @tax_declaration.stopped_on = params[:stopped_on].to_s if params.include? :stopped_on and params[:stopped_on].blank?
      end
      
    end       
    
    render_restfully_form
  end

  def destroy
    if request.post? or request.delete?
      @tax_declaration = TaxDeclaration.find_by_id_and_company_id(params[:id], @current_company.id) 
      TaxDeclaration.destroy @tax_declaration
    end    
    redirect_to :action => "tax_declarations"
  end

  def period_search
    if request.xhr?
      started_on =  params["started_on"].to_date
      
      @stopped_on=started_on.end_of_month if (["monthly"].include? params["period"])
      @stopped_on=(started_on.months_since 2).end_of_month.to_s if (["quarterly"].include? params["period"])
      @stopped_on=(started_on.months_since 11).end_of_month if (["yearly"].include? params["period"])
      @stopped_on='' if (["other"].include? params["period"])
      
      render :action=>"tax_declaration_period_search.rjs"

    end
  end

  def edit
    return unless find_and_check(:tax_declaration)
    render_restfully_form
  end

  def update
    return unless find_and_check(:tax_declaration)
    render_restfully_form
  end

  # Displays the main page with the list of tax declarations
  def index
    @journals  =  @current_company.journals.find(:all, :conditions => ["nature = ? OR nature = ?", :sale.to_s,  :purchase.to_s])
    
    if @journals.nil?
      notify(:need_journal_to_manage_tax_declaration, :now)
      redirect_to :action=>:journal_create
      return
    else
      @journals.each do |journal|
        unless journal.closable?(Date.today)
          notify(:need_balanced_journal_to_tax_declaration)
          # redirect_to :action=>:entries
          return
        end
      end

    end

  end

end
