class Backend::Cells::ProductPieCellsController < Backend::CellsController

  def show
    # GET DATA
    # for last campaign, show each production with product support and area
    if @campaign = Campaign.currents.first
      
      activities = Activity.of_campaign(@campaign).of_families(:straw_cereal_crops).order(:id)
      
      if activities.count > 0
        @activities = activities.collect do |activity|
          { name: activity.name, y: activity.shape_area.to_s.to_f }
        end
        @productions = Production.of_campaign(@campaign).of_activities(activities).order("activity_id, id").collect do |production|
          { name: production.name, y: production.shape_area.to_s.to_f }
        end
      end
    end
    
  end

end
