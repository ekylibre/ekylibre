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

class DocumentsController < ApplicationController

  def print
    # redirect_to :action=>:index
    @document_templates = @current_company.document_templates.find(:all, :conditions=>{:family=>"accountancy", :nature=>["journal", "general_journal", "general_ledger"]}, :order=>:name)
    @document_template = @current_company.document_templates.find_by_family_and_code("accountancy", params[:code])
    if request.xhr?
      render :partial=>'document_options'
      return
    end
    if request.post?
      if params[:export] == "balance"
        query  = "SELECT ''''||accounts.number, accounts.name, sum(COALESCE(journal_entry_lines.debit, 0)), sum(COALESCE(journal_entry_lines.credit, 0)), sum(COALESCE(journal_entry_lines.debit, 0)) - sum(COALESCE(journal_entry_lines.credit, 0))"
        query += " FROM #{JournalEntryLine.table_name} AS journal_entry_lines JOIN #{Account.table_name} AS accounts ON (account_id=accounts.id) JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)"
        query += " WHERE journal_entry_lines.company_id=#{@current_company.id} AND printed_on BETWEEN #{ActiveRecord::Base.connection.quote(params[:started_on].to_date)} AND #{ActiveRecord::Base.connection.quote(params[:stopped_on].to_date)}"
        query += " GROUP BY accounts.name, accounts.number"
        query += " ORDER BY accounts.number"
        begin
          result = ActiveRecord::Base.connection.select_rows(query)
          result.insert(0, ["N°Compte", "Libellé du compte", "Débit", "Crédit", "Solde"])
          result.insert(0, ["Balance du #{params[:started_on]} au #{params[:stopped_on]}"])
          csv_string = FasterCSV.generate do |csv|
            for line in result
              csv << line
            end
          end
          send_data(csv_string, :filename=>'export.csv', :type=>Mime::CSV)
        rescue Exception => e 
          notify(:exception_raised, :error, :now, :message=>e.message)
        end
      elsif params[:export] == "isaquare"
        path = Ekylibre::Export::AccountancySpreadsheet.generate(@current_company, params[:started_on].to_date, params[:stopped_on].to_date, @current_company.code+".ECC")
        send_file(path, :filename=>path.basename, :type=>Mime::ZIP)
      else
        redirect_to params.merge(:action=>:print, :controller=>:company)
      end
    end
    @document_template ||= @document_templates[0]
  end

end
