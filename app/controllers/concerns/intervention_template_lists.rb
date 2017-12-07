module InterventionTemplateLists
  extend ActiveSupport::Concern

  included do
    list(order: { created_at: :desc }) do |t|
      t.column :name
      t.column :active
      t.column :description
    end
  end
end
