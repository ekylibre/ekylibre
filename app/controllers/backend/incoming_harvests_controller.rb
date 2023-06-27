module Backend
  class IncomingHarvestsController < Backend::BaseController
    manage_restfully

    before_action :save_search_preference, only: %i[index show]

    def self.incoming_harvests_conditions
      code = search_conditions(incoming_harvests: %i[number ticket_number description]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{IncomingHarvest.table_name}.received_at BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"

      # # storage_name SILO
      code << "unless params[:storage_id].blank? \n"
      code << "  c[0] << ' AND #{IncomingHarvest.table_name}.id IN (SELECT incoming_harvest_id FROM #{IncomingHarvestStorage.table_name} WHERE storage_id = ?)'\n"
      code << "  c << params[:storage_id]\n"
      code << "end\n"

      # # driver_id DRIVER
      code << "unless params[:driver_id].blank? \n"
      code << "  c[0] << ' AND #{IncomingHarvest.table_name}.driver_id = ?'\n"
      code << "  c << params[:driver_id]\n"
      code << "end\n"

      # crop_name CULTURE / PARCELLE
      code << "unless params[:crop_id].blank? \n"
      code << "  c[0] << ' AND #{IncomingHarvest.table_name}.id IN (SELECT incoming_harvest_id FROM #{IncomingHarvestCrop.table_name} WHERE crop_id = ?)'\n"
      code << "  c << params[:crop_id]\n"
      code << "end\n"

      code << "c\n"
      code.c
    end

    list(:incoming_harvests, selectable: true, conditions: incoming_harvests_conditions, includes: %i[storages crops]) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :ticket_number, hidden: true
      t.column :received_at
      t.column :driver, hidden: true
      t.column :tractor, hidden: true
      t.column :trailer, hidden: true
      t.column :human_crops_names
      t.status
      t.column :quantity_value, on_select: :sum, value_method: :quantity, datatype: :bigdecimal
      t.column :quantity_unit
      t.column :human_storages_names, hidden: true
    end

    list(:crops, model: :incoming_harvest_crops, includes: :crop, conditions: { incoming_harvest_id: 'params[:id]'.c }) do |t|
      t.column :crop, url: true
      t.column :net_surface_area_crop, label: :total_area_in_hectare, datatype: :measure, class: 'center'
      t.column :harvest_percentage_repartition, label_method: :displayed_harvest_percentage, class: 'center'
      t.column :harvest_quantity, datatype: :measure, class: 'center'
      t.column :harvest_intervention, url: true
    end

    list(:storages, model: :incoming_harvest_storages, includes: :storage, conditions: { incoming_harvest_id: 'params[:id]'.c }) do |t|
      t.column :storage, url: true
      t.column :quantity, datatype: :measure, class: 'center'
    end

    def index
      # refresh materialized view
      IncomingHarvestIndicator.refresh
      @harvest_reception_document = DocumentTemplate.find_by(nature: :harvest_reception)
      dataset_params = {
        crop_id: params[:crop_id],
        driver_id: params[:driver_id],
        storage_id: params[:storage_id],
        period: params[:period],
        started_on: params[:started_on],
        stopped_on: params[:stopped_on]
      }
      respond_to do |format|
        format.html
        format.xml { render xml: resource_model.all }
        format.json { render json: resource_model.all }
        format.pdf {
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later('Printers::HarvestReceptionPrinter', template: template, perform_as: current_user, **dataset_params)
          notify_success(:document_in_preparation)
          redirect_to backend_incoming_harvests_path
        }
        format.odt {
          return unless (template = find_and_check :document_template, params[:template])

          printer = Printers::HarvestReceptionPrinter.new(template: template, **dataset_params)
          g = Ekylibre::DocumentManagement::DocumentGenerator.build
          send_data g.generate_odt(template: template, printer: printer), filename: "#{printer.document_name}.odt"
        }
      end
    end

    # link selected incoming harvest from list to existing harvest intervention
    def autolink_incoming_harvests
      incoming_harvest_ids = params[:incoming_harvest_ids].split(',') if params[:incoming_harvest_ids]
      if incoming_harvest_ids.any?
        AutolinkIncomingHarvestJob.perform_later(ih_ids: incoming_harvest_ids, user: current_user)
        notify_success(:harvest_intervention_updated_with_incoming_harvest_in_progress, incoming_harvest_count: incoming_harvest_ids.count)
      else
        notify_error(:missing_incoming_harvest)
      end
      redirect_to action: :index
    end

  end
end
