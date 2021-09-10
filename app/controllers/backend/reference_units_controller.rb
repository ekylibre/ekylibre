module Backend
  class ReferenceUnitsController < Backend::UnitsController
    manage_restfully
    unroll :name, :symbol

    list(conditions: units_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :symbol, class: 'center-align'
      t.column :description, hidden: true
      t.column :coefficient, class: 'right-align', label_method: :format_coefficient
      t.column :base_unit, class: 'center-align'
    end
  end
end
