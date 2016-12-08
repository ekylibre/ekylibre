module Backend
  class PlantCountingsController < Backend::BaseController
    manage_restfully except: :show

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :plant, url: true
      t.column :activity, url: true
      t.column :read_at, label: :date, datatype: :datetime
    end

    def show
      return unless @plant_counting = find_and_check
      notify_now :density_is_not_computable_in_counting unless @plant_counting.density_computable?
      respond_to do |format|
        format.html { t3e(@plant_counting.attributes) }
        format.xml  { render xml: @plant_counting }
        format.json
      end
    end
  end
end
