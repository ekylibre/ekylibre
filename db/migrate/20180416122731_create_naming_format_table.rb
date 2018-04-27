class CreateNamingFormatTable < ActiveRecord::Migration
  def change
    create_table :naming_formats do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.timestamps
    end

    create_table :naming_format_fields do |t|
      t.string :type, null: false
      t.string :field_name, null: false
      t.integer :position
      t.references :naming_format, index: true
    end

    create_default_land_parcel_naming
  end

  def create_default_land_parcel_naming
    locale = Entity.of_company.language.to_sym

    NamingFormatLandParcel.create(
      name: I18n.t('labels.land_parcels', locale: locale),
      fields: [
        new_land_parcel_field(:cultivable_zone_name, 1),
        new_land_parcel_field(:activity, 2),
        new_land_parcel_field(:campaign, 3)
      ]
    )
  end

  def new_land_parcel_field(field_name, position)
    NamingFormatFieldLandParcel.new(field_name: field_name, position: position)
  end
end
