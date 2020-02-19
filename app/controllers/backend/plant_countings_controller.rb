module Backend
  class PlantCountingsController < Backend::BaseController
    manage_restfully except: %i[index show]

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :plant, url: true
      t.column :activity, url: true
      t.column :read_at, label: :date, datatype: :datetime
    end

    def index
      respond_to do |format|
        format.html do
          notify_now(:feature_in_development, html: true) unless PlantCounting.any?
        end
        format.xml  { render xml:  resource_model.all }
        format.json { render json: resource_model.all }
      end
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
