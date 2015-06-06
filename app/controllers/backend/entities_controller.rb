# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::EntitiesController < Backend::BaseController
  manage_restfully nature: "(params[:nature] == 'contact' ? :contact : :organization)".c, active: true, t3e: {nature: "RECORD.nature.text".c}
  manage_restfully_picture

  unroll

  autocomplete_for :origin

  list(conditions: search_conditions(:entities => [:number, :full_name]), order: "entities.last_name, entities.first_name") do |t|
    t.action :edit
    t.action :destroy
    t.column :active, :datatype => :boolean
    t.column :nature
    t.column :last_name, url: true
    t.column :first_name, url: true
    t.column :number, url: true
    t.column :mail_line_6, through: :default_mail_address
  end

  list(:event_participations, conditions: {participant_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.action :edit
    t.action :destroy
    t.column :event
    t.status
    t.column :state, hidden: true
    # t.column :duration
    t.column :place, through: :event, hidden: true
    t.column :started_at, through: :event, datatype: :datetime
  end

  list(:incoming_payments, conditions: {payer_id: 'params[:id]'.c}, order: {created_at: :desc}, :line_class => "(RECORD.affair_closed? ? nil : 'warning')".c, per_page: 5) do |t|
    t.action :edit, if: :updateable?
    t.action :destroy, if: :destroyable?
    t.column :number, url: true
    t.column :paid_at
    t.column :responsible, hidden: true
    t.column :mode
    t.column :bank_name, hidden: true
    t.column :bank_check_number, hidden: true
    t.column :amount, currency: true, url: true
    t.column :deposit, url: true, hidden: true
  end

  list(:links, model: :entity_links, conditions: ["#{EntityLink.table_name}.stopped_at IS NULL AND (#{EntityLink.table_name}.entity_1_id = ? OR #{EntityLink.table_name}.entity_2_id = ?)", 'params[:id]'.c, 'params[:id]'.c], :per_page => 5) do |t|
    t.action :edit
    t.action :destroy
    t.column :entity_1, url: true
    t.column :nature
    t.column :entity_2, url: true
    t.column :description, hidden: true
  end

  list(:observations, conditions: {subject_id: 'params[:id]'.c, subject_type: "Entity"}, line_class: :importance, per_page: 5) do |t|
    t.action :edit
    t.action :destroy
    t.column :content
    t.column :importance
    t.column :observed_at
  end

  # Lists issues of the current product
  list(:issues, conditions: {target_id: 'params[:id]'.c, target_type: 'controller_name.classify.constantize'.c}, order: {observed_at: :desc}) do |t|
    t.action :edit
    t.action :destroy
    t.column :nature, url: true
    t.column :observed_at
    t.status
    t.column :creator
  end

  list(:outgoing_payments, conditions: {:payee_id => 'params[:id]'.c}, order: {created_at: :desc}, :line_class => "(RECORD.affair_closed? ? nil : 'warning')".c) do |t|
    t.action :edit
    t.action :destroy, if: :destroyable?
    t.column :number, url: true
    t.column :paid_at
    t.column :responsible, hidden: true
    t.column :mode, hidden: true
    t.column :bank_check_number, hidden: true
    t.column :amount, currency: true, url: true
  end

  list(:purchases, conditions: {:supplier_id => 'params[:id]'.c}, :line_class => "(RECORD.affair_closed? ? nil : 'warning')".c) do |t|
    # t.action :show, url: {format: :pdf}, image: :print, hidden: true
    t.action :edit
    t.action :destroy, if: :destroyable?, hidden: true
    t.column :number, url: true
    t.column :created_at, hidden: true
    t.column :invoiced_at
    t.column :delivery_address, hidden: true
    t.column :state_label
    t.column :amount, currency: true
  end

  list(:sales, conditions: {:client_id => 'params[:id]'.c}, :children => :items, :per_page => 5, order: {created_at: :desc}, :line_class => "(RECORD.affair_closed? ? nil : 'warning')".c) do |t|
    # t.action :show, url: {format: :pdf}, image: :print, hidden: true
    t.action :duplicate, method: :post, hidden: true
    t.action :edit, if: :draft?
    # t.action :destroy, if: :aborted?
    t.column :number, url: true, :children => :label
    t.column :responsible, children: false, hidden: true
    t.column :created_at,  children: false, hidden: true
    t.column :state_label, children: false
    t.column :amount, currency: true
  end


  list(:subscriptions, conditions: {subscriber_id:  'params[:id]'.c}, order: 'stopped_at DESC, first_number DESC', :line_class => "(RECORD.active? ? 'enough' : '')".c) do |t|
    t.action :edit
    t.action :destroy
    t.column :number
    t.column :nature
    t.column :start
    t.column :finish
    t.column :sale, url: true, hidden: true
    t.column :address, hidden: true
    t.column :quantity, :datatype => :decimal, hidden: true
    t.column :suspended, hidden: true
  end


  def export
    if request.xhr?
      render :partial => 'export_condition'
    else
      @columns = Entity.exportable_columns
      @conditions = ["special-subscriber"] # , "special-buyer", "special-relation"]
      @conditions += Entity.exportable_columns.collect{|c| "generic-entity-#{c.name}"}.sort
      @conditions += EntityAddress.exportable_columns.collect{|c| "generic-entity-address-#{c.name}"}.sort
      @conditions += ["generic-postal_zone-postal_code", "generic-postal_zone-city"]
      @conditions += ["generic-district-name"]
      if request.post?
        from  = " FROM #{Entity.table_name} AS entity"
        from += " LEFT JOIN #{EntityAddress.table_name} AS address ON (address.entity_id=entity.id AND address.by_default IS TRUE AND address.deleted_at IS NULL)"
        from += " LEFT JOIN #{PostalZone.table_name} AS postal_zone ON (address.postal_zone_id=postal_zone.id})"
        from += " LEFT JOIN #{District.table_name} AS district ON (postal_zone.district_id=district.id)"
        where = " WHERE entity.active"
        select_array = []
        for k, v in params[:columns].select{|k,v| v[:check].to_i == 1}.sort{|a,b| a[1][:order].to_i <=> b[1][:order].to_i}
          if k.match(/^custom_field\-/)
            id = k.split('-')[1][2..-1].to_i
            if custom_field = CustomField.find_by_id(id)
              # from += " LEFT JOIN #{CustomFieldDatum.table_name} AS _c#{id} ON (entity.id=_c#{id}.entity_id AND _c#{id}.custom_field_id=#{id})"
              if custom_field.nature == "choice"
                select_array << [ "_cc#{id}.value AS custom_field_#{id}", v[:label]]
                # from += " LEFT JOIN #{CustomFieldChoice.table_name} AS _cc#{id} ON (_cc#{id}.id=_c#{id}.choice_value_id)"
                from += " LEFT JOIN #{CustomFieldChoice.table_name} AS _cc#{id} ON (_cc#{id}.id=#{custom_field.column_name})"
              else
                # select_array << [ "_c#{id}.#{custom_field.nature}_value AS custom_field_#{id}", v[:label]]
                select_array << [ "#{custom_field.column_name} AS custom_field_#{id}", v[:label]]
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
                       subscribed_at = ""
                       if subn[:use_subscribed_at]
                         subscribed_at = " AND ("+
                           if nature.period?
                             x = subn[:subscribed_at].to_date rescue Date.today
                             "'"+ActiveRecord::Base.connection.quoted_date(x)+"'"
                           else
                             subn[:subscribed_at].to_i.to_s
                           end+" BETWEEN #{nature.start} AND #{nature.finish})"
                       end
                       timestamp = ""
                       if condition[:use_timestamp]
                         x = condition[:timestamp][:started_at].to_date rescue Date.today
                         y = condition[:timestamp][:stopped_at].to_date rescue Date.today
                         timestamp = " AND (created_at BETWEEN '#{ActiveRecord::Base.connection.quoted_date(x)}' AND '#{ActiveRecord::Base.connection.quoted_date(y)}')"
                       end
                       "entity.id IN (SELECT entity_id FROM #{Subscription.table_name} AS subscriptions WHERE nature_id=#{nature.id}"+products+subscribed_at+timestamp+")"
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
        csv_string = CSV.generate do |csv|
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
        redirect_to action: :import, id: :columns
      end
    elsif @step == :columns
      unless File.exist?(session[:entities_import_file].to_s)
        redirect_to action: :import, id: :upload
      end
      csv = CSV.open(session[:entities_import_file])
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
        # raise StandardError.new columns.inspect+"\n"+cols.inspect
        session[:entities_import_cols] = cols
        redirect_to action: :import, id: :validate
      end
    elsif @step == :validate
      file, cols = session[:entities_import_file], session[:entities_import_cols]
      if request.post?
        @report = Entity.import(file, cols, :no_simulation => true, :ignore => session[:entities_import_ignore])
        notify_success(:importation_finished)
        redirect_to action: :import, id: :upload
      else
        @report = Entity.import(file, cols)
        session[:entities_import_ignore] = @report[:errors].keys
      end
    end
  end

  def merge
    if request.post?
      return unless @master = find_and_check(id: params[:master])
      return unless @double = find_and_check(id: params[:double])
      if @master.id == @double.id
        notify_error_now(:cannot_merge_an_entity_with_itself)
        return
      end
      @master.merge_with(@double, current_user)
      begin
        notify_success(:merge_is_done)
        redirect_to action: :show, id: @master.id
      rescue
        notify_error_now(:cannot_merge_entities)
      end
    end
  end


end
