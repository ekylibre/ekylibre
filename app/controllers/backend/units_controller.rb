module Backend
  class UnitsController < Backend::BaseController
    unroll

    def self.units_conditions
      code = search_conditions(units: %i[name symbol]) + " ||= []\n"
      code << "c\n"
      code.c
    end

    list(:products, conditions: { conditioning_unit_id: 'params[:id]'.c }, order: { born_at: :desc }) do |t|
      t.column :name, url: { controller: '/backend/products' }
      t.column :work_number
      t.column :identification_number
      t.column :born_at, datatype: :datetime
      t.column :population
    end

    def unroll_filters_by_dimensions
      variant = ProductNatureVariant.find(params[:filter_id])
      scope = { of_dimensions: variant.compatible_dimensions }

      respond_to do |format|
        format.json { render json: { scope_url: unroll_backend_units_path(scope: scope),
                                     new_url: new_backend_conditioning_path(base_unit_id: variant.default_unit) } }
      end
    end

    def show
      unit = Unit.find(params[:id])
      respond_to do |format|
        format.json { render json: { id: unit.id, reference_name: unit.reference_name, dimension: unit.dimension } }
      end
    end

    def unroll_filters_by_catalog_items
      variant = ProductNatureVariant.find(params[:filter_id])
      scope = { of_variant: [variant.id] }

      respond_to do |format|
        format.json { render json: { scope_url: unroll_backend_units_path(scope: scope),
                                     new_url: new_on_the_go_backend_conditionings_path(variant_id: variant.id, base_unit_id: variant.default_unit) } }
      end
    end

    def conditioning_data
      unit = Unit.find(params[:filter_id])
      variant = ProductNatureVariant.find(params[:variant_id])
      coefficient = UnitComputation.convert_into_variant_default_unit(variant, 1, unit)

      respond_to do |format|
        format.json { render json: { coefficient: coefficient, unit_name: unit.name } }
      end
    end
  end
end
