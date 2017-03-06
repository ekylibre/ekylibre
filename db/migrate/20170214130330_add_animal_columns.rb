class AddAnimalColumns < ActiveRecord::Migration
  def change
    add_column :products, :birth_date_completeness, :string
    add_column :products, :birth_farm_number, :string
    add_column :products, :country, :string
    add_column :products, :filiation_status, :string
    add_column :products, :first_calving_on, :datetime
    add_column :products, :mother_country, :string
    add_column :products, :mother_variety, :string
    add_column :products, :mother_identification_number, :string
    add_column :products, :father_country, :string
    add_column :products, :father_variety, :string
    add_column :products, :father_identification_number, :string
    add_column :products, :origin_country, :string
    add_column :products, :origin_identification_number, :string
    add_column :products, :end_of_life_reason, :string

    add_column :product_movements, :description, :string
  end
end
