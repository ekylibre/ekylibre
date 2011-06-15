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

class MyselvesController < ApplicationController

  def statistics
    params[:stopped_on] = params[:stopped_on].to_date rescue Date.today
    params[:started_on] = params[:started_on].to_date rescue params[:stopped_on] << 12
#     session[:statistics_start] ||= Date.today << 12
#     session[:statistics_end]   ||= Date.today
#     @sales_count = Sale.count_by_sql ["SELECT  count(*) FROM #{Sale.table_name} WHERE company_id = ? AND state != 'P' AND responsible_id = ? AND created_on BETWEEN ? AND ? ", @current_company.id, @current_user.id, session[:statistics_start], session[:statistics_end] ]
#     @sales_amount = Sale.count_by_sql ["SELECT sum(amount) FROM #{Sale.table_name} WHERE company_id = ? AND state != 'P' AND responsible_id = ? AND created_on BETWEEN ? AND ? ", @current_company.id, @current_user.id, session[:statistics_start], session[:statistics_end] ]
#     @invoiced_amount = SalesInvoice.count_by_sql ["SELECT sum(sales_invoices.amount) FROM #{SalesInvoice.table_name} AS sales_invoices INNER JOIN #{Sale.table_name} AS sales ON sales.responsible_id = ? AND sales_invoices.sale_id = sales.id WHERE sales_invoices.company_id = ? AND sales_invoices.payment_on BETWEEN ? AND ? ", @current_user.id,  @current_company.id,session[:statistics_start], session[:statistics_end] ]
#     @event_natures = EventNature.find_by_sql ["SELECT en.*, ecount, esum FROM #{EventNature.table_name} AS en LEFT JOIN (SELECT nature_id , count(id) as ecount, sum(duration) as esum FROM #{Event.table_name} WHERE started_at BETWEEN ? AND ? AND responsible_id = ? GROUP BY nature_id) as stats ON id = nature_id  WHERE company_id = ? ORDER BY name ", session[:statistics_start].to_date.beginning_of_day, session[:statistics_end].to_date.end_of_day, @current_user.id, @current_company.id]
#     if request.post?
#       session[:statistics_start] = params[:start].to_date
#       session[:statistics_end] = params[:end].to_date
#       redirect_to_current
#     end
  end

  def change_password
    @user = @current_user
    if request.post?
      if @user.authenticated? params[:user][:old_password]
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.save
          notify(:password_successfully_changed, :success)
          redirect_to :action=>:index 
        end
        @user.password = @user.password_confirmation = ''
      else
        @user.errors.add(:old_password, :invalid) 
      end      
    end
  end

end
