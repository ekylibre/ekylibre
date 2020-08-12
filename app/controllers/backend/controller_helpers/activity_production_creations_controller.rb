module Backend
    module ControllerHelpers
        class ActivityProductionCreationsController < Backend::BaseController

            def new
              model = FormObjects::Backend::ControllerHelpers::ActivityProductionCreations::CreationHelper.new(campaign: current_campaign.id, cultivable_zone: params[:cultivable_zone])

              render partial: 'form', locals: { model: model }
            end

            def create
                creation_helper = FormObjects::Backend::ControllerHelpers::ActivityProductionCreations::CreationHelper.new(permitted_params)
                
                if creation_helper.valid?
                    js_redirect_to new_backend_activity_production_path(campaign_id: creation_helper.campaign, activity_id: creation_helper.activity, cultivable_zone_id: creation_helper.cultivable_zone)
                else
                    render status: 400, partial: 'form', locals: { model: creation_helper }
                end
            end

            private

                def permitted_params
                    params.require(:activity_production_creation)
                          .permit(:campaign, :activity, :cultivable_zone)
                end

                def js_redirect_to(path)
                  render js: "window.location='#{path}'"
                end
        end
    end
end