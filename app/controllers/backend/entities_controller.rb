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

module Backend
  class EntitiesController < Backend::BaseController
    manage_restfully nature: "(params[:nature] == 'contact' ? :contact : :organization)".c,
                     language: 'Preference[:language]'.c,
                     country: 'Preference[:country]'.c,
                     active: true,
                     t3e: { nature: 'RECORD.nature.text'.c }
    manage_restfully_picture

    unroll fill_in: :full_name

    autocomplete_for :title, :first_name, :last_name, :meeting_origin

    # params:
    #   :q Text search
    def self.entities_conditions
      code = ''
      code = search_conditions(entities: [:number, :full_name], entity_addresses: [:coordinate]) + " ||= []\n"
      code << "unless params[:state].blank?\n"
      code << "  if params[:state].include?('client')\n"
      code << "    c[0] << ' AND #{Entity.table_name}.client IS TRUE'\n"
      code << "  end\n"
      code << "  if params[:state].include?('supplier')\n"
      code << "    c[0] << ' AND #{Entity.table_name}.supplier IS TRUE'\n"
      code << "  end\n"
      code << "  if params[:state].include?('active')\n"
      code << "    c[0] << ' AND #{Entity.table_name}.active IS TRUE'\n"
      code << "  end\n"
      code << "end\n"

      code << "unless params[:nature].blank?\n"
      code << "  if Entity.nature.values.include?(params[:nature].to_sym)\n"
      code << "    c[0] << ' AND #{Entity.table_name}.nature = ?'\n"
      code << "    c << params[:nature]\n"
      code << "  end\n"
      code << "end\n"

      code << "unless params[:mail_line_6].blank?\n"
      code << "  c[0] << ' AND #{Entity.table_name}.id IN (SELECT entity_id FROM entity_addresses WHERE mail_line_6 ILIKE E? AND by_default AND deleted_at IS NULL)'\n"
      code << "  c << '%' + params[:mail_line_6].to_s.strip.gsub(/[\,\s\-]+/, '%') + '%'\n"
      code << "end\n"

      code << "unless params[:subscription_nature_id].blank? || params[:subscription_test].blank?\n"
      code << "  if params[:subscription_test] == 'subscribed_on'\n"
      code << "    c[0] << ' AND #{Entity.table_name}.id IN (SELECT subscriber_id FROM subscriptions WHERE nature_id = ? AND ? BETWEEN started_on AND stopped_on)'\n"
      code << "    c << params[:subscription_nature_id]\n"
      code << "    c << params[:subscribed_on]\n"
      code << "  elsif params[:subscription_test] == 'expired_within'\n"
      code << "    c[0] << ' AND #{Entity.table_name}.id IN (SELECT s.subscriber_id FROM subscriptions AS s LEFT JOIN subscriptions AS ns ON (ns.subscriber_id = s.subscriber_id AND ns.stopped_on > s.stopped_on AND ns.nature_id = ?) WHERE s.nature_id = ? AND ns.id IS NULL AND s.stopped_on <= CURRENT_DATE + ?::INTERVAL)'\n"
      code << "    c << params[:subscription_nature_id]\n"
      code << "    c << params[:subscription_nature_id]\n"
      code << "    c << params[:expired_within] + ' days'\n"
      code << "  elsif params[:subscription_test] == 'expired_since'\n"
      code << "    c[0] << ' AND #{Entity.table_name}.id IN (SELECT s.subscriber_id FROM subscriptions AS s LEFT JOIN subscriptions AS ns ON (ns.subscriber_id = s.subscriber_id AND ns.stopped_on > s.stopped_on AND ns.nature_id = ?) WHERE s.nature_id = ? AND ns.id IS NULL AND CURRENT_DATE >= s.stopped_on + ?::INTERVAL)'\n"
      code << "    c << params[:subscription_nature_id]\n"
      code << "    c << params[:subscription_nature_id]\n"
      code << "    c << params[:expired_since] + ' days'\n"
      code << "  end\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: entities_conditions, order: 'entities.last_name, entities.first_name') do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :active, datatype: :boolean
      t.column :nature
      t.column :last_name, url: true
      t.column :first_name, url: true
      t.column :number, url: true
      t.column :mail_line_1, through: :default_mail_address, hidden: true
      t.column :mail_line_2, through: :default_mail_address, hidden: true
      t.column :mail_line_3, through: :default_mail_address, hidden: true
      t.column :mail_line_4, through: :default_mail_address, hidden: true
      t.column :mail_line_5, through: :default_mail_address, hidden: true
      t.column :mail_line_6, through: :default_mail_address
      t.column :email, label_method: :coordinate, through: :default_email_address, hidden: true
      t.column :phone, label_method: :coordinate, through: :default_phone_address, hidden: true
      t.column :mobile, label_method: :coordinate, through: :default_mobile_address, hidden: true
      # Deactivated for performance reason, need to store it in one column
      # t.column :balance, currency: true, hidden: true
    end

    list(:event_participations, conditions: { participant_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :event
      t.status
      t.column :state, hidden: true
      # t.column :duration
      t.column :place, through: :event, hidden: true
      t.column :started_at, through: :event, datatype: :datetime
    end

    list(:incoming_payments, conditions: { payer_id: 'params[:id]'.c }, order: { created_at: :desc }, line_class: "(RECORD.affair_closed? ? nil : 'warning')".c, per_page: 5) do |t|
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

    list(:links, model: :entity_links, conditions: ["#{EntityLink.table_name}.stopped_at IS NULL AND (#{EntityLink.table_name}.entity_id = ? OR #{EntityLink.table_name}.linked_id = ?)", 'params[:id]'.c, 'params[:id]'.c], per_page: 5) do |t|
      t.action :edit
      t.action :destroy
      t.column :entity, url: true
      t.column :nature
      t.column :linked, url: true
      t.column :description, hidden: true
    end

    list(:observations, conditions: { subject_id: 'params[:id]'.c, subject_type: 'Entity' }, line_class: :importance, per_page: 5) do |t|
      t.action :edit
      t.action :destroy
      t.column :content
      t.column :importance
      t.column :observed_at
    end

    # Lists issues of the current product
    list(:issues, conditions: { target_id: 'params[:id]'.c, target_type: 'controller_name.classify.constantize'.c }, order: { observed_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :nature, url: true
      t.column :observed_at
      t.status
      t.column :creator
    end

    list(:outgoing_payments, conditions: { payee_id: 'params[:id]'.c }, order: { created_at: :desc }, line_class: "(RECORD.affair_closed? ? nil : 'warning')".c) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :paid_at
      t.column :responsible, hidden: true
      t.column :mode, hidden: true
      t.column :bank_check_number, hidden: true
      t.column :amount, currency: true, url: true
    end

    list(:purchases, conditions: { supplier_id: 'params[:id]'.c }, line_class: "(RECORD.affair_closed? ? nil : 'warning')".c) do |t|
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

    list(:sales, conditions: { client_id: 'params[:id]'.c }, per_page: 5, order: { created_at: :desc }, line_class: "(RECORD.affair_closed? ? nil : 'warning')".c) do |t|
      # t.action :show, url: {format: :pdf}, image: :print, hidden: true
      t.action :duplicate, method: :post, hidden: true, if: :duplicatable?
      t.action :edit, if: :draft?
      # t.action :destroy, if: :aborted?
      t.column :number, url: true, children: :label
      t.column :responsible, children: false, hidden: true
      t.column :created_at,  children: false, hidden: true
      t.column :invoiced_at, children: false, hidden: true
      t.column :state_label, children: false
      t.column :amount, currency: true
    end

    list(:sale_opportunities, conditions: { third_id: 'params[:id]'.c }, per_page: 5, order: { created_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :dead_line_at
      t.column :created_at,  hidden: true
      t.column :responsible, url: true
      t.column :pretax_amount, currency: true
    end

    list(:subscriptions, conditions: { subscriber_id: 'params[:id]'.c }, order: { stopped_on: :desc }, line_class: "(RECORD.suspended ? 'squeezed' : '')".c) do |t|
      t.action :edit
      t.action :renew, method: :post, if: 'current_user.can?(:write, :sales) && RECORD.renewable?'.c
      t.action :suspend, method: :post, if: :suspendable?
      t.action :takeover, method: :post, if: :suspended
      t.action :destroy
      t.column :number, url: true
      t.column :nature, url: true
      t.column :address, hidden: true
      t.column :started_on
      t.column :stopped_on
      t.column :sale, url: true
      t.column :quantity, hidden: true
      t.column :suspended, hidden: true
    end

    list(:tasks, conditions: { entity_id: 'params[:id]'.c }, order: :state, line_class: 'RECORD.state'.c) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :nature
      t.column :state
      t.status
      t.column :due_at
      t.column :sale_opportunity, url: true
      t.column :executor, url: true
    end

    def import
      @step = begin
                params[:id].to_sym
              rescue
                :upload
              end
      if @step == :upload
        @formats = [['CSV', :csv]] # , ["CSV Excel", :xcsv], ["XLS Excel", :xls], ["OpenDocument", :ods]]
        if request.post? && params[:upload]
          data = params[:upload]
          tmp = Rails.root.join('tmp', 'uploads')
          FileUtils.mkdir_p(tmp)
          file = tmp.join("entities_import_#{data.original_filename.gsub(/[^\w]/, '_')}")
          File.open(file, 'wb') { |f| f.write(data.read) }
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
          all_columns = params[:columns].dup.delete_if { |_k, v| v.match(/^special-dont_use/) || v.blank? }
          columns = params[:columns].delete_if { |_k, v| v.match(/^special-/) || v.blank? }
          if (columns.values.size - columns.values.uniq.size) > 0
            notify_error_now(:columns_are_already_uses)
            return
          end
          cols = {}
          columns = all_columns
          for prefix in columns.values.collect { |x| x.split(/\-/)[0] }.uniq
            cols[prefix.to_sym] = {}
            columns.select { |_k, v| v.match(/^#{prefix}-/) }.each { |k, v| cols[prefix.to_sym][k.to_s] = v.split(/\-/)[1].to_sym }
          end
          cols[:entity] ||= {}
          if cols[:entity].keys.size <= 0 || !cols[:entity].values.detect { |x| x == :last_name }
            notify_error_now(:entity_columns_are_needed)
            return
          end
          # raise StandardError.new columns.inspect+"\n"+cols.inspect
          session[:entities_import_cols] = cols
          redirect_to action: :import, id: :validate
        end
      elsif @step == :validate
        file = session[:entities_import_file]
        cols = session[:entities_import_cols]
        if request.post?
          @report = Entity.import(file, cols, no_simulation: true, ignore: session[:entities_import_ignore])
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
end
