class Backend::Cells::ProductPieCellsController < Backend::CellsController

  def show
    # GET DATA
    # for last campaign, show each production with product support and area
    campaign = Campaign.currents.first
    
    activities = Activity.of_campaign(campaign).of_families(:straw_cereal_crops)
    
    activity_values = activities.collect do |activity|
      {
        name: activity.name,
        y: activity.shape_area
      }
    end
          
     production_values = Production.of_campaign(campaign).of_activities(activities).collect do |production|
      {
        name: production.name,
        y: production.shape_area
      }
     end          
      
     # SET SERIES FOR CHART
     @series = [{
                name: Activity.model_name.human,
                data: activity_values,
                size: '60%'
                },
                {
                name: Production.model_name.human,
                data: production_values,
                size: '60%',
                innersize: '80%'
                }]
                
     
     
  end

end