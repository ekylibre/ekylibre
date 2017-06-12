module Backend
  class ReceptionsController < Backend::ParcelsController
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
    def self.receptions_conditions
      code = search_conditions(receptions: %i[number reference_number], entities: %i[full_name number]) + " ||= []\n"
      code << "unless params[:period].blank? || params[:period].is_a?(Symbol)\n"
      code << "  if params[:period] != 'all'\n"
      code << "    interval = params[:period].split('_')\n"
      code << "    first_date = interval.first\n"
      code << "    last_date = interval.last\n"
      code << "    c[0] << \" AND #{Reception.table_name}.planned_at::DATE BETWEEN ? AND ?\"\n"
      code << "    c << first_date\n"
      code << "    c << last_date\n"
      code << "  end\n "
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
      code << "  c[0] << ' AND (#{Reception.table_name}.purchase_id IS NOT NULL OR #{Reception.table_name}.sale_id IS NOT NULL) '\n"
      code << "elsif params[:invoice_status] && params[:invoice_status] == 'uninvoiced'\n"
      code << "  c[0] << ' AND (#{Reception.table_name}.purchase_id IS NULL AND #{Reception.table_name}.sale_id IS NULL) '\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: receptions_conditions, order: { planned_at: :desc }) do |t|
      t.action :invoice, on: :both, method: :post, if: :invoiceable?
      t.action :ship,    on: :both, method: :post, if: :shippable?
      t.action :edit, if: :updateable?
      t.action :destroy
      t.column :number, url: true
      t.column :reference_number, hidden: true
      t.column :content_sentence, label: :contains
      t.column :planned_at
      t.column :given_at
      t.column :sender, url: true
      t.status
      t.column :state, label_method: :human_state_name
      t.column :delivery, url: true
      t.column :responsible, url: true, hidden: true
      t.column :transporter, url: true, hidden: true
      # t.column :sent_at
      t.column :delivery_mode
      # t.column :net_mass, hidden: true
      t.column :purchase, url: true
    end

    list(:items, model: :parcel_items, order: { id: :asc }, conditions: { parcel_id: 'params[:id]'.c }) do |t|
      t.column :variant, url: true
      # t.column :source_product, url: true
      t.column :product_name
      t.column :product_identification_number
      t.column :population
      t.column :unit_name, through: :variant
      t.column :unit_pretax_amount, currency: true
      t.status
      # t.column :net_mass
      t.column :product, url: true
      t.column :analysis, url: true
    end

  end
end
