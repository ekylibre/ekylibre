module Backend
  class InterventionTemplatesController < Backend::BaseController

    # Include the list for the index or other
    include InterventionTemplateLists

    def select_type
      @family = Nomen::ActivityFamily.find('plant_farming')
      @categories = Nomen::ProcedureCategory.select { |c| c.activity_family.include?(@family.name.to_sym) }
    end

    def new
      # Set options from params for the new
      options = {}
      %i[procedure_name].each { |p| options[p] = params[p] }
      options[:campaign] = current_campaign
      @intervention_template = InterventionTemplate.new(options)
      procedure
      # Translate the name of the procedure for the title
      t3e(procedure_name: @procedure.human_name, campaign_name: current_campaign.name)
      @no_menu = true
      render(locals: { with_continue: true })
    end

    def create
      @intervention_template = InterventionTemplate.new(permitted_params)
      respond_to do |format|
        if @intervention_template.save
          format.json { render json: @intervention_template, status: :created }
        else
          format.json { render json: @intervention_template.errors, status: :unprocessable_intervention_template }
        end
      end
    end

    def update
      find_intervention_template
      respond_to do |format|
        if @intervention_template.update(permitted_params)
          format.json { render json: @intervention_template, status: :ok }
        else
          format.json { render json: @intervention_template.errors, status: :unprocessable_intervention_template }
        end
      end
    end

    def show
      find_intervention_template
      # t3e(procedure_name: @procedure.human_name)
    end

    def edit
      find_intervention_template
      procedure
      t3e(procedure_name: @procedure.human_name, campaign_name: @intervention_template.campaign.name)
    end

    private

    def find_intervention_template
      @intervention_template = InterventionTemplate.find(params[:id])
    end

    def procedure
      @procedure = @intervention_template.procedure
    end

    def permitted_params
      params.require(:intervention_template).permit(:name,
                                                    :active,
                                                    :description,
                                                    :procedure_name,
                                                    :workflow,
                                                    :preparation_time_hours,
                                                    :preparation_time_minutes,
                                                    :campaign_id,
                                                    product_parameters_attributes: [:id,
                                                                                    :product_nature_id,
                                                                                    :product_nature_variant_id,
                                                                                    :quantity,
                                                                                    :unit,
                                                                                    :_destroy,
                                                                                    procedure: [:name, :type],
                                                                                  ],
                                                    association_activities_attributes: [:id,
                                                                                        :activity_id,
                                                                                        :_destroy])
    end
  end
end
