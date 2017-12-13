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
      @intervention_template = InterventionTemplate.new(options)
      @procedure = @intervention_template.procedure
      # Translate the name of the procedure for the title
      t3e(procedure_name: @procedure.human_name)
      @no_menu = true
      render(locals: { with_continue: true })
    end

    def create
      @intervention_template = InterventionTemplate.new(permitted_params)
      binding.pry
      respond_to do |format|
        if @intervention_template.save
          format.json { render json: @intervention_template, status: :created }
        else
          format.json { render json: @intervention_template.errors, status: :unprocessable_intervention_template }
        end
      end
    end

    private

    def permitted_params
      params.require(:intervention_template).permit(:name,
                                                    :active,
                                                    :description,
                                                    :procedure_name,
                                                    product_parameters_attributes: [:id,
                                                                                    :product_nature_id,
                                                                                    :product_nature_variant_id,
                                                                                    :quantity,
                                                                                    :unit,
                                                                                    :_destroy],
                                                    association_activities_attributes: [:id,
                                                                                        :activity_id,
                                                                                        :_destroy])
    end
  end
end
