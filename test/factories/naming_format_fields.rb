FactoryBot.define do
  factory :naming_format_field do
    field_name { 'cultivable_zone_name' }
    sequence(:position)
    type { 'NamingFormatFieldLandParcel' }
    naming_format
  end
end
