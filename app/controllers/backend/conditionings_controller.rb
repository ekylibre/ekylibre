module Backend
  class ConditioningsController < Backend::UnitsController
    manage_restfully

    list(conditions: units_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :work_code
      t.column :description, hidden: true
      t.column :coefficient, class: 'right-align', label_method: :format_coefficient
      t.column :base_unit, class: 'center-align'
    end

    def new_on_the_go
      @conditioning = Conditioning.new(base_unit_id: params[:base_unit_id])
      @fieldset_label = :create_a_new_conditioning
      @scope = {}
      if variant = ProductNatureVariant.find_by_id(params[:variant_id])
        @scope[:of_dimensions] = variant.compatible_dimensions
      end
      notify_now :link_conditioning_to_variant_guidance.tl
    end

    def create_on_the_go
      @conditioning = Conditioning.new(permitted_params)
      if params[:association_mode] == 'existing' && Unit.find_by_id(params[:unit_id])
        response.headers['X-Return-Code'] = 'success'
        response.headers['X-Saved-Record-Id'] = params[:unit_id]
        head :ok
      elsif params[:association_mode] == 'new' && @conditioning.save
        response.headers['X-Return-Code'] = 'success'
        response.headers['X-Saved-Record-Id'] = @conditioning.id.to_s
        head :ok
      else
        @fieldset_label = :create_a_new_conditioning
        @association_mode = params[:association_mode]
        notify_now :link_conditioning_to_variant_guidance.tl
        render :new_on_the_go
      end
    end
  end
end
