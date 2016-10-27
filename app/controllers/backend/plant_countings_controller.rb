module Backend
  class PlantCountingsController < Backend::BaseController
    manage_restfully

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :plant, url: true
      t.column :read_at, datatype: :datetime
    end
  end
end