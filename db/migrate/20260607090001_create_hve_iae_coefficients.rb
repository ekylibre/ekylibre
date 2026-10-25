class CreateHveIaeCoefficients < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_iae_coefficients do |t|
      t.string  :iae_family, null: false   # aquatique | herbager | ligneux | rocheux
      t.string  :iae_type,   null: false   # haie | mare | bande_enherbee | arbre_isole | prairie_permanente | …
      t.string  :unit,       null: false   # 'ha' | 'm'
      t.decimal :coefficient, precision: 6, scale: 3, null: false
      t.string  :description
      t.timestamps null: false
    end
    add_index :hve_iae_coefficients, %i[iae_family iae_type unit], unique: true, name: :index_hve_iae_coefs_unique
  end
end
