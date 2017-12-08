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
      %i[procedure_name].each { |p| options[p] = params[p]}
      @intervention_template = InterventionTemplate.new(options)
      @procedure = @intervention_template.procedure
      @no_menu = true
      render(locals: { with_continue: true })
    end

    def create
      @intervention_template = InterventionTemplate.new(permitted_params)
      if @intervention_template.save
        redirect_to(backend_intervention_templates_path)
      end
    end


    private

    def permitted_params
      params.require(:intervention_template).permit(:name, :active, :description, product_parameters_attributes: [:id, :product, :quantity, :_destroy])
    end
  end
end
