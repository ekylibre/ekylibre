module Backend
  class RideSetsController < Backend::BaseController
    manage_restfully

    unroll

    list(selectable: true, order: { started_at: :desc }) do |t|
      t.column :number, url: true
      t.column :nature
      t.column :state, label_method: :decorated_state
      t.column :created_at
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :road, class: 'center'
      t.column :main_equipment, url: { controller: 'backend/equipments', id: "RECORD.equipments.of_nature('main').first.product_id".c }
      t.column :additional_tool_one, url: { controller: 'backend/equipments', id: "RECORD.equipments.of_nature('additional')[0].product_id".c }, hidden: :additional_tool_one.nil?
      t.column :additional_tool_two, url: { controller: 'backend/equipments', id: "RECORD.equipments.of_nature('additional')[1].product_id".c }, hidden: :additional_tool_two.nil?
      t.column :provider_vendor
    end


    list(:rides, selectable: true, model: :ride, conditions: { ride_set_id: 'params[:id]'.c }, order: 'rides.started_at DESC',
line_class: 'RECORD.state'.c) do |t|
      t.column :number, url: true, class: 'ride-title'
      t.column :intervention, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :main_equipment, url: { controller: 'backend/equipments', id: "RECORD.ride_set.equipments.of_nature('main').first.product_id".c }
      t.column :additional_tool_one, url: { controller: 'backend/equipments', id: "RECORD.ride_set.equipments.of_nature('additional')[0].product_id".c }, hidden: :additional_tool_one.nil?
      t.column :additional_tool_two, url: { controller: 'backend/equipments', id: "RECORD.ride_set.equipments.of_nature('additional')[1].product_id".c }, hidden: :additional_tool_two.nil?
      t.column :provider_vendor, label_method: :provider_vendor 
    end

    def index
      notify_ride_set_information

      if params[:ride_set_job_notify]
        notify_now(params[:ride_set_job_notify])
      end
      
      super
    end

    def synchronize
      SamsysFetchUpdateCreateJob.perform_later(stopped_on: Time.now.to_s, started_on: (Time.now - 2.days).to_s, user_id: current_user.id)
      redirect_to backend_ride_sets_path
    end

    def delete_selected_ride_sets
      SamysDeleteSelectedRideSetsJob.perform_later(ride_set_ids: params["ride_set_ids"].map(&:to_i), user_id: current_user.id)
      redirect_to backend_ride_sets_path(ride_set_job_notify: :delete_ride_set_processing.tl)
    end

    private

      def notify_ride_set_information
        if RideSet.count.zero?
          notify_warning_now(helpers.link_to(:ride_set_message.tl, backend_integrations_path))
        else
          notify_now(:ride_set_to_ride_information.tl)
        end
      end
  end
end
