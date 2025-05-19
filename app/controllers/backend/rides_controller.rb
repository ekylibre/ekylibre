module Backend
  class RidesController < Backend::BaseController

    manage_restfully

    unroll

    def self.rides_conditions
      search_conditions(rides: [:equipment])
    end

    list(conditions: rides_conditions, order: { started_at: :desc }) do |t|
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :equipment, url: { controller: 'backend/equipments', id: 'RECORD.product_id'.c }
      t.column :provider_name
      t.column :state
    end
  end
end
