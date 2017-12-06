module Backend
  class InterventionTemplatesController < Backend::BaseController

    def select_type
      @family = Nomen::ActivityFamily.find('plant_farming')
      @categories = Nomen::ProcedureCategory.select { |c| c.activity_family.include?(@family.name.to_sym) }
    end

    def new
    end
  end
end
