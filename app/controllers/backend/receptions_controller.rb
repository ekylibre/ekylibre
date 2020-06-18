module Backend
  class ReceptionsController < Backend::ParcelsController
    manage_restfully except: %i[new create update]

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

    before_action :save_search_preference, only: :index
    unroll

    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :recipient_id
    #   :sender_id
    #   :transporter_id
    #   :delivery_mode Choice
    #   :nature Choice
    def self.receptions_conditions
      code = search_conditions(receptions: %i[number reference_number], entities: %i[full_name number]) + " ||= []\n"
      code << "if params[:period].present? && params[:period] != 'all'\n"
      code << "  if params[:period] == 'interval' \n"
      code << "    started_on = params[:started_on] \n"
      code << "    stopped_on = params[:stopped_on] \n"
      code << "  else \n"
      code << "    interval = params[:period].split('_')\n"
      code << "    started_on = interval.first\n"
      code << "    stopped_on = interval.last\n"
      code << "  end \n"
      code << "  c[0] << \" AND #{Reception.table_name}.planned_at::DATE BETWEEN ? AND ?\"\n"
      code << "  c << started_on\n"
      code << "  c << stopped_on\n"
      code << "end\n "

      code << "if params[:recipient_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Reception.table_name}.recipient_id = ?\"\n"
      code << "  c << params[:recipient_id].to_i\n"
      code << "end\n"

      code << "if params[:sender_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Reception.table_name}.sender_id = ?\"\n"
      code << "  c << params[:sender_id].to_i\n"
      code << "end\n"

      code << "if params[:transporter_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Reception.table_name}.transporter_id = ?\"\n"
      code << "  c << params[:transporter_id].to_i\n"
      code << "end\n"

      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Reception.table_name}.responsible_id = ?\"\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"

      code << "if params[:delivery_mode].present? && params[:delivery_mode] != 'all'\n"
      code << "  if Reception.delivery_mode.values.include?(params[:delivery_mode].to_sym)\n"
      code << "    c[0] << ' AND #{Reception.table_name}.delivery_mode = ?'\n"
      code << "    c << params[:delivery_mode]\n"
      code << "  end\n"
      code << "end\n"

      code << "if params[:invoice_status] && params[:invoice_status] == 'invoiced'\n"
      code << "   c[0] << ' AND #{Reception.table_name}.id IN (SELECT parcel_id FROM #{ReceptionItem.table_name} WHERE #{ReceptionItem.table_name}.type = \\'ReceptionItem\\' AND #{ReceptionItem.table_name}.purchase_invoice_item_id IS NOT NULL)'\n"
      code << "elsif params[:invoice_status] && params[:invoice_status] == 'uninvoiced'\n"
      code << "   c[0] << ' AND #{Reception.table_name}.id IN (SELECT parcel_id FROM #{ReceptionItem.table_name} WHERE #{ReceptionItem.table_name}.type = \\'ReceptionItem\\' AND #{ReceptionItem.table_name}.purchase_invoice_item_id IS NULL)'\n"
      code << "end\n"
      code << "c\n"

      code.c
    end

    list(conditions: receptions_conditions, order: { planned_at: :desc }) do |t|
      t.action :edit, if: :updateable?
      t.action :destroy
      t.column :number, url: true
      t.column :reference_number, hidden: true
      t.column :content_sentence, label: :contains
      t.column :planned_at
      t.column :given_at
      t.column :sender, url: true
      t.status
      t.column :state, hidden: true
      t.column :delivery, url: true
      t.column :responsible, url: true, hidden: true
      t.column :transporter, url: true, hidden: true
      # t.column :sent_at
      t.column :delivery_mode
      # t.column :net_mass, hidden: true
      # t.column :purchase, url: true
    end

    list(:items, model: :parcel_items, order: { id: :asc }, conditions: { parcel_id: 'params[:id]'.c, role: 'service' }) do |t|
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :purchase_order_number, label: :order, through: :parcel_item, url: { controller: '/backend/purchase_orders', id: 'RECORD.purchase_order_item.purchase.id'.c }
      t.column :purchase_invoice_number, label: :invoice, url: { controller: 'backend/purchase_invoices', id: 'RECORD.purchase_invoice_item.purchase.id'.c }
      # t.column :source_product, url: true
      t.column :product_name
      t.column :product_work_number
      t.column :population
      t.column :unit_name, through: :variant
      t.column :unit_pretax_amount, currency: true
      t.status
      # t.column :net_mass
      # t.column :product, url: true
      t.column :analysis, url: true
    end

    list(:storings, model: :parcel_item_storings, order: { id: :asc }, conditions: { parcel_item_id: 'Reception.find(params[:id]).items.pluck(:id)'.c }) do |t|
      t.column :variant, label_method: :name, through: :parcel_item, url: { controller: 'RECORD.parcel_item.variant.class.name.tableize'.c, id: 'RECORD.parcel_item.variant_id'.c, namespace: :backend }
      t.column :purchase_order_number, label: :order, through: :parcel_item, url: { controller: '/backend/purchase_orders', id: 'RECORD.parcel_item.purchase_order_item.purchase.id'.c }
      t.column :purchase_invoice_number, label: :invoice, through: :parcel_item, url: { controller: '/backend/purchase_invoices', id: 'RECORD.parcel_item.purchase_invoice_item.purchase.id'.c }
      t.column :product_name, through: :parcel_item
      t.column :product_work_number, through: :parcel_item
      t.column :storage, url: true
      t.column :product, url: true
      t.column :quantity
      t.column :unit_name, through: :parcel_item
      t.column :unit_pretax_amount, currency: true, through: :parcel_item
      t.column :analysis, url: true, through: :parcel_item
    end

    def new
      if params[:purchase_order_ids]
        purchase_orders = PurchaseOrder.find(params[:purchase_order_ids].split(','))
        supplier_ids = purchase_orders.map(&:supplier_id)

        reception_attributes = {
          sender_id: supplier_ids.uniq.length > 1 ? nil : supplier_ids.first,
          given_at: Date.today,
          reconciliation_state: 'reconcile',
          items: ReceivableItemsFilter.new.filter(purchase_orders)
        }

        @reception = Reception.new(reception_attributes)
      else
        @reception = Reception.new
      end

      render locals: { with_continue: true }
    end

    def create
      @reception = Reception.new(permitted_params)

      if @reception.items.blank?
        @reception.validate(:perform_validations)
        notify_error_now :reception_need_at_least_one_item
      else
        return if save_and_redirect(@reception,
                                    url: (params[:create_and_continue] ? { :action => :new, :continue => true } : (params[:redirect] || ({ action: :show, id: 'id'.c }))),
                                    notify: ((params[:create_and_continue] || params[:redirect]) ? :record_x_created : false),
                                    identifier: :number)
      end
      render(locals: { cancel_url: { :action => :index }, with_continue: false })
    end

    def update
      return unless @reception = find_and_check(:reception)

      t3e(@reception.attributes)

      @reception.assign_attributes(permitted_params)

      if @reception.items.all?(&:marked_for_destruction?)
        notify_error_now :reception_need_at_least_one_item
      elsif @reception.save
        return redirect_to(params[:redirect] || { action: :show, id: @reception.id },
                           notify: :record_x_updated,
                           identifier: :number)
      end
      render(locals: { cancel_url: { :action => :index }, with_continue: false })
    end

    def give
      return unless (record = find_and_check)

      transition = Reception::Transitions::Give.new(record, given_at: record.given_at.presence || Time.zone.now)

      ok = transition.run

      unless ok
        notify_error helpers.render_transition_error(transition.error), html: true
      end

      redirect_action = ok ? :show : :edit
      redirect_to params[:redirect] || { action: redirect_action, id: record.id }
    end
  end
end
