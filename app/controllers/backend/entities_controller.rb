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

class Backend::EntitiesController < BackendController
  manage_restfully

  unroll_all

  autocomplete_for :origin

  # # list(:select => {[:addresses, :mail_line_6] => :item_6}, :conditions => search_conditions(:entities, :entities => [:number, :full_name], :addresses => [:coordinate]), :joins => "LEFT JOIN #{EntityAddress.table_name} AS addresses ON (entities.id = addresses.entity_id AND addresses.deleted_at IS NULL)", :order => "entities.number") do |t|
  # list(:select => {[:addresses, :coordinate] => :coordinate}, :conditions => search_conditions(:entities, :entities => [:number, :full_name], :addresses => [:coordinate]), :joins => "LEFT JOIN #{EntityAddress.table_name} AS addresses ON (entities.id = addresses.entity_id AND addresses.deleted_at IS NULL)", :order => "entities.last_name, entities.first_name") do |t|
  list(:conditions => search_conditions(:entities, :entities => [:number, :full_name]), :order => "entities.last_name, entities.first_name") do |t| # , :joins => "LEFT JOIN #{EntityAddress.table_name} AS addresses ON (entities.id = addresses.entity_id AND addresses.deleted_at IS NULL)" # , :addresses => [:coordinate]
    t.column :active, :datatype => :boolean
    t.column :number, :url => true
    t.column :nature
    t.column :last_name, :url => true
    t.column :first_name, :url => true
    # t.column :coordinate # :item_6
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    # t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of entities
  def index
    session[:entity_key] = params[:q]
  end

  # list(:addresses, :model => :entity_addresses, :conditions => ['deleted_at IS NULL AND (entity_id = ? OR entity_id IN ( SELECT entity_1_id FROM #{EntityLink.table_name} INNER JOIN #{EntityLinkNature.table_name} ON (#{EntityLinkNature.table_name}.propagate_addresses = ? AND #{EntityLink.table_name}.nature_id = #{EntityLinkNature.table_name}.id AND stopped_at IS NULL) WHERE (entity_1_id = ? OR entity_2_id = ?)) OR entity_id IN (SELECT entity_2_id FROM #{EntityLink.table_name} INNER JOIN #{EntityLinkNature.table_name} ON #{EntityLinkNature.table_name}.propagate_addresses = ? AND #{EntityLink.table_name}.nature_id = #{EntityLinkNature.table_name}.id  AND stopped_at IS NULL WHERE (entity_1_id = ? OR entity_2_id = ?)))', ['session[:current_entity_id]'], true, ['session[:current_entity_id]'], ['session[:current_entity_id]'], true, ['session[:current_entity_id]'], ['session[:current_entity_id]'] ]) do |t|
  #   t.column :address, :url => {:action => :edit}
  #   t.column :phone
  #   t.column :fax
  #   t.column :mobile
  #   t.column :email
  #   t.column :website
  #   t.column :by_default
  #   t.column :number, :through => :entity, :url => true
  #   t.action :edit
  #   t.action :destroy
  # end

  # TODO: Filter meetings with participations , :conditions => {:entity_id => ['session[:current_entity_id]']}
  list(:meeting_participations, :order => "created_at DESC") do |t|
    t.column :name, :through => :meeting
    t.column :state
    # t.column :label, :through => :responsible, :url => true
    # t.column :duration
    # t.column :place
    t.column :started_at, :through => :meeting
    t.action :edit
    t.action :destroy
  end

  list(:incoming_payments, :conditions => {:payer_id => ['session[:current_entity_id]']}, :order => "created_at DESC") do |t| # , :line_class => "(RECORD.used_amount!=RECORD.amount ? 'warning' : nil)"
    t.column :number, :url => true
    t.column :paid_on
    t.column :label, :through => :responsible
    t.column :name, :through => :mode
    t.column :bank_name
    t.column :bank_check_number
    # t.column :used_amount, :currency => "RECORD.mode.cash.currency"
    t.column :amount, :currency => true, :url => true
    t.column :number, :through => :deposit, :url => true
    t.action :edit, :if => "RECORD.deposit.nil\?"
    t.action :destroy, :if => :destroyable?
  end

  list(:links, :model => :entity_links, :conditions => ['#{EntityLink.table_name}.stopped_at IS NULL AND (#{EntityLink.table_name}.entity_1_id = ? OR #{EntityLink.table_name}.entity_2_id = ?)', ['session[:current_entity_id]'], ['session[:current_entity_id]']], :per_page => 5) do |t|
    t.column :description, :through => :entity_1, :url => true
    t.column :nature
    t.column :description, :through => :entity_2, :url => true
    t.column :description
    t.action :edit
    t.action :destroy
  end

  list(:mandates, :conditions => {:entity_id => ['session[:current_entity_id]']}) do |t|
    t.column :title
    t.column :organization, :url => {:controller => :mandates, :action => :index}
    t.column :family
    t.column :started_on, :datatype => :date
    t.column :stopped_on, :datatype => :date
    t.action :edit
    t.action :destroy
  end

  list(:observations, :conditions => {:subject_id => ['session[:current_entity_id]'], :subject_type => "Entity"}, :per_page => 5) do |t| # , :line_class => 'RECORD.status'
    t.column :content
    t.column :importance
    t.action :edit
    t.action :destroy
  end

  list(:outgoing_payments, :conditions => {:payee_id => ['session[:current_entity_id]']}, :order => "created_at DESC") do |t| # , :line_class => "(RECORD.used_amount!=RECORD.amount ? 'warning' : nil)"
    t.column :number, :url => true
    t.column :paid_on
    t.column :label, :through => :responsible
    t.column :name, :through => :mode
    t.column :bank_check_number
    # t.column :used_amount, :currency => "RECORD.mode.cash.currency"
    t.column :amount, :currency => true, :url => true
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  list(:purchases, :model => :purchase, :conditions => {:supplier_id => ['session[:current_entity_id]']}, :line_class => 'RECORD.status') do |t|
    t.column :number, :url => true
    t.column :created_on
    t.column :invoiced_on
    t.column :address, :through => :delivery_address
    t.column :state_label
    # t.column :paid_amount, :currency => true
    t.column :amount, :currency => true
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  list(:sales, :conditions => {:client_id => ['session[:current_entity_id]']}, :children => :items, :per_page => 5, :order => "created_on DESC") do |t| # , :line_class => 'RECORD.tags'
    t.column :number, :url => true, :children => :label
    t.column :full_name, :through => :responsible, :children => false
    t.column :created_on, :children => false
    t.column :state_label, :children => false
    # t.column :paid_amount, :currency => {:body => true, :children => "RECORD.sale.currency"}, :children => false
    t.column :amount, :currency => {:body => true, :children => "RECORD.sale.currency"}
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :duplicate, :method => :post
    t.action :edit, :if => "RECORD.draft? "
    t.action :destroy, :if => "RECORD.aborted? "
  end

  list(:subscriptions, :conditions => {:subscriber_id => ['session[:current_entity_id]']}, :order => 'stopped_on DESC, first_number DESC', :line_class => "(RECORD.active? ? 'enough' : '')") do |t|
    t.column :number
    t.column :name, :through => :nature
    t.column :start
    t.column :finish
    t.column :number, :through => :sale, :url => true
    t.column :coordinate, :through => :address
    t.column :quantity, :datatype => :decimal
    t.column :suspended
    t.action :edit
    t.action :destroy
  end

  # Displays details of one entity selected with +params[:id]+
  def show
    return unless @entity = find_and_check(:entity)
    respond_to do |format|
      format.html do
        session[:current_entity_id] = @entity.id
        session[:my_entity] = params[:id]
        t3e @entity.attributes
        @key = ""
      end
      format.pdf { render_print_entity(@entity) }
    end
  end


  def picture
    return unless @entity = find_and_check
    if @entity.picture.file?
      send_file(@entity.picture.path(params[:style] || :original))
    else
      head :not_found
    end
  end


  def export
    if request.xhr?
      render :partial => 'export_condition'
    else
      @columns = Entity.exportable_columns
      @conditions = ["special-subscriber"] # , "special-buyer", "special-relation"]
      @conditions += Entity.exportable_columns.collect{|c| "generic-entity-#{c.name}"}.sort
      @conditions += EntityAddress.exportable_columns.collect{|c| "generic-entity-address-#{c.name}"}.sort
      @conditions += ["generic-area-postcode", "generic-area-city"]
      @conditions += ["generic-district-name"]
      if request.post?
        from  = " FROM #{Entity.table_name} AS entity"
        from += " LEFT JOIN #{EntityAddress.table_name} AS address ON (address.entity_id=entity.id AND address.by_default IS TRUE AND address.deleted_at IS NULL)"
        from += " LEFT JOIN #{Area.table_name} AS area ON (address.area_id=area.id})"
        from += " LEFT JOIN #{District.table_name} AS district ON (area.district_id=district.id)"
        where = " WHERE entity.active"
        select_array = []
        for k, v in params[:columns].select{|k,v| v[:check].to_i == 1}.sort{|a,b| a[1][:order].to_i <=> b[1][:order].to_i}
          if k.match(/^custom_field\-/)
            id = k.split('-')[1][2..-1].to_i
            if custom_field = CustomField.find_by_id(id)
              from += " LEFT JOIN #{CustomFieldDatum.table_name} AS _c#{id} ON (entity.id=_c#{id}.entity_id AND _c#{id}.custom_field_id=#{id})"
              if custom_field.nature == "choice"
              select_array << [ "_cc#{id}.value AS custom_field_#{id}", v[:label]]
                from += " LEFT JOIN #{CustomFieldChoice.table_name} AS _cc#{id} ON (_cc#{id}.id=_c#{id}.choice_value_id)"
              else
                select_array << [ "_c#{id}.#{custom_field.nature}_value AS custom_field_#{id}", v[:label]]
              end
            end
          else
            select_array << [k.gsub('-', '.'), v[:label]]
          end
        end
        if params[:conditions]
          code = params[:conditions].collect do |id, preferences|
            condition = preferences[:type]
            expr = if condition == "special-subscriber"
                     if nature = SubscriptionNature.find_by_id(preferences[:nature])
                       subn = preferences[preferences[:nature]]
                       products = (subn[:products]||{}).select{|k,v| v.to_i==1 }.collect{|k,v| k}
                       products = "product_id IN (#{products.join(', ')})" if products.size > 0
                       products = "#{products+' OR ' if products.is_a?(String) and subn[:no_products]}#{'product_id IS NULL' if subn[:no_products]}"
                       products = " AND (#{products})" unless products.blank?
                       subscribed_on = ""
                       if subn[:use_subscribed_on]
                         subscribed_on = " AND ("+
                           if nature.period?
                             x = subn[:subscribed_on].to_date rescue Date.today
                             "'"+ActiveRecord::Base.connection.quoted_date(x)+"'"
                           else
                             subn[:subscribed_on].to_i.to_s
                           end+" BETWEEN #{nature.start} AND #{nature.finish})"
                       end
                       timestamp = ""
                       if condition[:use_timestamp]
                         x = condition[:timestamp][:started_on].to_date rescue Date.today
                         y = condition[:timestamp][:stopped_on].to_date rescue Date.today
                         timestamp = " AND (created_at BETWEEN '#{ActiveRecord::Base.connection.quoted_date(x)}' AND '#{ActiveRecord::Base.connection.quoted_date(y)}')"
                       end
                       "entity.id IN (SELECT entity_id FROM #{Subscription.table_name} AS subscriptions WHERE nature_id=#{nature.id}"+products+subscribed_on+timestamp+")"
                     else
                       "true"
                     end
                   elsif condition.match(/^generic/)
                     klass, attribute = condition.split(/\-/)[1].classify.constantize, condition.split(/\-/)[2]
                     column = klass.columns_hash[attribute]
                     ListingNode.condition(condition.split(/\-/)[1..2].join("."), preferences[:comparator], preferences[:comparated], column.sql_type)
                   end
            "\n"+(preferences[:reverse].to_i==1 ? "NOT " : "")+"(#{expr})"
          end.join(params[:check] == "and" ? " AND " : " OR ")
          where += " AND (#{code})"
        end
        select = "SELECT "+select_array.collect{|x| x[0]}.join(", ")
        query = select+"\n"+from+"\n"+where

        result = ActiveRecord::Base.connection.select_rows(query)
        result.insert(0, select_array.collect{|x| x[1]})
        csv_string = Ekylibre::CSV.generate do |csv|
          for item in result
            csv << item
          end
        end
        send_data(csv_string, :filename => 'export.csv', :type => Mime::CSV)
      end
    end
  end

  def import
    @step = params[:id].to_sym rescue :upload
    if @step == :upload
      @formats = [["CSV", :csv]] # , ["CSV Excel", :xcsv], ["XLS Excel", :xls], ["OpenDocument", :ods]]
      if request.post? and params[:upload]
        data, tmp = params[:upload], Rails.root.join("tmp", "uploads")
        FileUtils.mkdir_p(tmp)
        file = tmp.join("entities_import_#{data.original_filename.gsub(/[^\w]/,'_')}")
        File.open(file, "wb") { |f| f.write(data.read)}
        session[:entities_import_file] = file
        redirect_to :action => :import, :id => :columns
      end
    elsif @step == :columns
      unless File.exist?(session[:entities_import_file].to_s)
        redirect_to :action => :import, :id => :upload
      end
      csv = Ekylibre::CSV.open(session[:entities_import_file])
      @columns = csv.shift
      @first_item = csv.shift
      @options = Entity.importable_columns
      if request.post?
        all_columns = params[:columns].dup.delete_if{|k,v| v.match(/^special-dont_use/) or v.blank?}
        columns = params[:columns].delete_if{|k,v| v.match(/^special-/) or v.blank?}
        if (columns.values.size - columns.values.uniq.size) > 0
          notify_error_now(:columns_are_already_uses)
          return
        end
        cols = {}
        columns = all_columns
        for prefix in columns.values.collect{|x| x.split(/\-/)[0]}.uniq
          cols[prefix.to_sym] = {}
          columns.select{|k,v| v.match(/^#{prefix}-/)}.each{|k,v| cols[prefix.to_sym][k.to_s] = v.split(/\-/)[1].to_sym}
        end
        cols[:entity] ||= {}
        if cols[:entity].keys.size <= 0 or not cols[:entity].values.detect{|x| x == :last_name}
          notify_error_now(:entity_columns_are_needed)
          return
        end
        # raise Exception.new columns.inspect+"\n"+cols.inspect
        session[:entities_import_cols] = cols
        redirect_to :action => :import, :id => :validate
      end
    elsif @step == :validate
      file, cols = session[:entities_import_file], session[:entities_import_cols]
      if request.post?
        @report = Entity.import(file, cols, :no_simulation => true, :ignore => session[:entities_import_ignore])
        notify_success(:importation_finished)
        redirect_to :action => :import, :id => :upload
      else
        @report = Entity.import(file, cols)
        session[:entities_import_ignore] = @report[:errors].keys
      end
    end
  end

  def merge
    if request.post?
      return unless @master = find_and_check(:entity, params[:merge][:master])
      return unless @double = find_and_check(:entity, params[:merge][:double])
      if @master.id == @double.id
        notify_error_now(:cannot_merge_an_entity_with_itself)
        return
      end
      begin
        @master.merge(@double, true)
      rescue
        notify_error_now(:cannot_merge_entities)
      end
    end
  end


end
