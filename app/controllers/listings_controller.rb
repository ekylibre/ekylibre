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

class ListingsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name, :url=>{:action=>:edit}
    t.column :root_model_name
    t.column :comment
    t.action :extract, :url=>{:format=>:csv}, :image=>:action
    t.action :extract, :url=>{:format=>:csv, :mode=>:no_mail}, :if=>'RECORD.mail_columns.size > 0', :image=>:nomail
    t.action :mail, :if=>'RECORD.mail_columns.size > 0'
    t.action :duplicate, :method=>:post
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of listings
  def index
    session[:listing_mail_column] = nil
  end

  def extract
    return unless @listing = find_and_check(:listing)

    begin
      @listing.save if @listing.query.blank?
      query = @listing.query.to_s
      # FIXME: This is dirty code to solve quickly no_mail mode
      query.gsub!(" ORDER BY ", " AND ("+@listing.mail_columns.collect{|c| "#{c.name} NOT LIKE '%@%.%'" }.join(" AND ")+") ORDER BY ") if params[:mode] == "no_mail"
      query.gsub!(/CURRENT_COMPANY/i, @current_company.id.to_s)
      first_line = []
      @listing.exportable_columns.each {|line| first_line << line.label}
      result = ActiveRecord::Base.connection.select_rows(query)
      result.insert(0, first_line)
      
      respond_to do |format|
        format.xml { render :xml => result.to_xml, :filename=>@listing.name.simpleize+'.xml' }
        format.csv do        
          csv_string = Ekylibre::CSV.generate do |csv|
            for line in result
              csv << line
            end
          end
          send_data(csv_string, :filename=>@listing.name.simpleize+'.csv', :type=>Mime::CSV)
        end
      end
      
    rescue Exception=>e
      notify_error(:fails_to_extract_listing, :message=>e.message)
      redirect_to_current
    end
  end



  def new
    if request.post?
      @listing = Listing.new(params[:listing])
      @listing.company_id = @current_company.id
      return if save_and_redirect(@listing, :url=>{:action=>:edit, :id=>"id"})
    else
      @listing = Listing.new
    end
    render_restfully_form
  end

  def create
    if request.post?
      @listing = Listing.new(params[:listing])
      @listing.company_id = @current_company.id
      return if save_and_redirect(@listing, :url=>{:action=>:edit, :id=>"id"})
    else
      @listing = Listing.new
    end
    render_restfully_form
  end

  def destroy
    return unless @listing = find_and_check(:listing)
    if request.post? or request.delete?
      Listing.destroy(@listing.id) if @listing
    end
    redirect_to :action=>:index
  end

  def duplicate
    return unless @listing = find_and_check(:listing)
    @listing.duplicate if request.post?
    redirect_to :action=>:index
  end

  def mail
    return unless @listing = find_and_check(:listing)
    if (query = @listing.query).blank?
      @listing.save 
      query = @listing.query
    end
    query = query.to_s
    if @listing.mail_columns.size == 0 or query.blank?
      notify_warning(:you_must_have_an_email_column)
      redirect_to_back
      return
    end
    if session[:listing_mail_column] or @listing.mail_columns.size ==  1
      query.gsub!(/CURRENT_COMPANY/i, @current_company.id.to_s)
      full_results = ActiveRecord::Base.connection.select_all(query)
      listing_mail_column = @listing.mail_columns.size == 1 ? @listing.mail_columns[0] : find_and_check(:listing_nodes, session[:listing_mail_column])
      #raise Exception.new listing_mail_column.inspect
      results = full_results.select{|c| !c[listing_mail_column.label].blank? }
      @mails = results.collect{|c| c[listing_mail_column.label] }
      # @mails.uniq! ### CHECK ????????
      @columns = (full_results.size > 0 ? full_results[0].keys.sort : [])
      session[:mail] ||= {}
    end
    if request.post?
      if params[:node]
        session[:listing_mail_column] = ListingNode.find_by_company_id_and_key(@current_company.id, params[:node][:mail]).id
        redirect_to_current
      else
        session[:mail] = params.dup
        session[:mail].delete(:attachment)
        texts = [params[:mail_subject], params[:mail_body]]
        attachment = params[:attachment]
        if attachment
          # file = "#{Rails.root.to_s}/tmp/uploads/attachment_#{attachment.original_filename.gsub(/\W/,'_')}"
          # File.open(file, "wb") { |f| f.write(attachment.read)}
          attachment = {:filename=>attachment.original_filename, :content_type=>attachment.content_type, :body=>attachment.read.dup}
        end
        if params[:send_test]
          results = [results[0]]
          results[0][listing_mail_column.label] = params[:from]
        end
        for result in results
          ts = texts.collect do |t|
            r = t.to_s.dup
            @columns.each{|c| r.gsub!(/\{\{#{c}\}\}/, result[c].to_s)}
            r
          end
          Mailman.deliver_message(params[:from], result[listing_mail_column.label], ts[0], ts[1], attachment)
          notify_success_now(:mails_are_sent)
        end
        nature = @current_company.event_natures.find(:first, :conditions=>{:usage=>"mailing"}).nil? ? @current_company.event_natures.create!(:name=>tc(:mailing), :duration=>5, :usage=>"mailing").id : @current_company.event_natures.find(:first, :conditions=>{:usage=>"mailing"})
        #raise Exception.new nature.inspect
        for contact in @current_company.contacts.find(:all, :conditions=>["email IN (?) AND active = ? ", @mails, true])
          @current_company.events.create!(:entity_id=>contact.entity_id, :started_at=>Time.now, :duration=>5, :nature_id=>nature.id, :user_id=>@current_user.id)
        end
        session[:listing_mail_column] = nil
      end
    end
    t3e :listing => @listing.name
  end

  def edit
    return unless @listing = find_and_check(:listing)
    t3e @listing.attributes
  end

  def update
    edit
    @listing.attributes = params[:listing]
    return if save_and_redirect(@listing, :url=>{:action=>:edit, :id=>"id"})
    render :edit
  end

end
