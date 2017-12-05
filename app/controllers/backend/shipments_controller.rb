module Backend
  class ShipmentsController < Backend::ParcelsController
    manage_restfully

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

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
    def self.shipments_conditions
      code = search_conditions(shipments: %i[number reference_number], entities: %i[full_name number]) + " ||= []\n"
      code << "unless params[:period].blank? || params[:period].is_a?(Symbol)\n"
      code << "  if params[:period] != 'all'\n"
      code << "    interval = params[:period].split('_')\n"
      code << "    first_date = interval.first\n"
      code << "    last_date = interval.last\n"
      code << "    c[0] << \" AND #{Shipment.table_name}.planned_at::DATE BETWEEN ? AND ?\"\n"
      code << "    c << first_date\n"
      code << "    c << last_date\n"
      code << "  end\n "
      code << "end\n "
      code << "if params[:recipient_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Shipment.table_name}.recipient_id = ?\"\n"
      code << "  c << params[:recipient_id].to_i\n"
      code << "end\n"
      code << "if params[:sender_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Shipment.table_name}.sender_id = ?\"\n"
      code << "  c << params[:sender_id].to_i\n"
      code << "end\n"
      code << "if params[:transporter_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Shipment.table_name}.transporter_id = ?\"\n"
      code << "  c << params[:transporter_id].to_i\n"
      code << "end\n"
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] << \" AND \#{Shipment.table_name}.responsible_id = ?\"\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "if params[:delivery_mode].present? && params[:delivery_mode] != 'all'\n"
      code << "  if Shipment.delivery_mode.values.include?(params[:delivery_mode].to_sym)\n"
      code << "    c[0] << ' AND #{Shipment.table_name}.delivery_mode = ?'\n"
      code << "    c << params[:delivery_mode]\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:invoice_status] && params[:invoice_status] == 'invoiced'\n"
      code << "  c[0] << ' AND (#{Shipment.table_name}.purchase_id IS NOT NULL OR #{Shipment.table_name}.sale_id IS NOT NULL) '\n"
      code << "elsif params[:invoice_status] && params[:invoice_status] == 'uninvoiced'\n"
      code << "  c[0] << ' AND (#{Shipment.table_name}.purchase_id IS NULL AND #{Shipment.table_name}.sale_id IS NULL) '\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: shipments_conditions, order: { planned_at: :desc }) do |t|
      t.action :ship, on: :both, method: :post, if: :shippable?
      t.action :edit, if: :updateable?
      t.action :destroy
      t.column :number, url: true
      t.column :reference_number, hidden: true
      t.column :content_sentence, label: :contains
      t.column :planned_at
      t.column :given_at
      t.column :recipient, url: true
      t.status
      t.column :state, label_method: :human_state_name
      t.column :delivery, url: true
      t.column :responsible, url: true, hidden: true
      t.column :transporter, url: true, hidden: true
      # t.column :sent_at
      t.column :delivery_mode
      # t.column :net_mass, hidden: true
      t.column :sale, url: true
    end

    list(:items, model: :parcel_items, conditions: { parcel_id: 'params[:id]'.c }) do |t|
      t.column :source_product, url: true
      t.column :product, url: true, hidden: true
      t.column :product_work_number, through: :product, label_method: :work_number, hidden: true
      t.column :product_identification_number, hidden: true
      t.column :population
      t.column :unit_name, through: :variant
      # t.column :variant, url: true
      t.status
      # t.column :net_mass
      t.column :analysis, url: true
    end

    Shipment.state_machine.events.each do |event|
      define_method event.name do
        fire_event(event.name)
      end
    end

    # Pre-fill delivery form with given parcels. Nothing else.
    # Only a shortcut now.
    def ship
      parcels = find_parcels
      return unless parcels
      parcel = parcels.detect(&:shippable?)
      options = { parcel_ids: parcels.map(&:id) }
      if !parcel
        redirect_to(options.merge(controller: :deliveries, action: :new))
      elsif parcels.all? { |p| p.shippable? && (p.delivery_mode == parcel.delivery_mode) }
        options[:mode] = parcel.delivery_mode
        options[:transporter_id] = parcel.transporter_id if parcel.transporter
        redirect_to(options.merge(controller: :deliveries, action: :new))
      else
        notify_error(:some_parcels_are_not_shippable)
        redirect_to(params[:redirect] || { action: :index })
      end
    end
  end
end
