# Migration generated with nomenclature migration #20150821230800
class RenameInvalidDocumentNature < ActiveRecord::Migration
  def up
    # Change item document_natures#vat_registry with {:name=>"vat_register"}
    execute "UPDATE document_templates SET nature='vat_register' WHERE nature='vat_registry'"
    execute "UPDATE documents SET nature='vat_register' WHERE nature='vat_registry'"
    execute "UPDATE attachments SET nature='vat_register' WHERE nature='vat_registry'"
    # Change item document_natures#animal_husbandry_registry with {:name=>"animal_husbandry_register"}
    execute "UPDATE document_templates SET nature='animal_husbandry_register' WHERE nature='animal_husbandry_registry'"
    execute "UPDATE documents SET nature='animal_husbandry_register' WHERE nature='animal_husbandry_registry'"
    execute "UPDATE attachments SET nature='animal_husbandry_register' WHERE nature='animal_husbandry_registry'"
    # Change item document_natures#intervention_registry with {:name=>"intervention_register"}
    execute "UPDATE document_templates SET nature='intervention_register' WHERE nature='intervention_registry'"
    execute "UPDATE documents SET nature='intervention_register' WHERE nature='intervention_registry'"
    execute "UPDATE attachments SET nature='intervention_register' WHERE nature='intervention_registry'"
    # Change item document_natures#land_parcel_registry with {:name=>"land_parcel_register"}
    execute "UPDATE document_templates SET nature='land_parcel_register' WHERE nature='land_parcel_registry'"
    execute "UPDATE documents SET nature='land_parcel_register' WHERE nature='land_parcel_registry'"
    execute "UPDATE attachments SET nature='land_parcel_register' WHERE nature='land_parcel_registry'"
    # Change item document_natures#phytosanitary_registry with {:name=>"phytosanitary_register"}
    execute "UPDATE document_templates SET nature='phytosanitary_register' WHERE nature='phytosanitary_registry'"
    execute "UPDATE documents SET nature='phytosanitary_register' WHERE nature='phytosanitary_registry'"
    execute "UPDATE attachments SET nature='phytosanitary_register' WHERE nature='phytosanitary_registry'"
    # Change item document_natures#wine_manipulation_registry with {:name=>"wine_manipulation_register"}
    execute "UPDATE document_templates SET nature='wine_manipulation_register' WHERE nature='wine_manipulation_registry'"
    execute "UPDATE documents SET nature='wine_manipulation_register' WHERE nature='wine_manipulation_registry'"
    execute "UPDATE attachments SET nature='wine_manipulation_register' WHERE nature='wine_manipulation_registry'"
    # Change item document_natures#wine_bottling_registry with {:name=>"wine_bottling_register"}
    execute "UPDATE document_templates SET nature='wine_bottling_register' WHERE nature='wine_bottling_registry'"
    execute "UPDATE documents SET nature='wine_bottling_register' WHERE nature='wine_bottling_registry'"
    execute "UPDATE attachments SET nature='wine_bottling_register' WHERE nature='wine_bottling_registry'"
    # Change item document_natures#wine_detention_registry with {:name=>"wine_detention_register"}
    execute "UPDATE document_templates SET nature='wine_detention_register' WHERE nature='wine_detention_registry'"
    execute "UPDATE documents SET nature='wine_detention_register' WHERE nature='wine_detention_registry'"
    execute "UPDATE attachments SET nature='wine_detention_register' WHERE nature='wine_detention_registry'"
    # Change item document_natures#vine_phytosanitary_registry with {:name=>"vine_phytosanitary_register"}
    execute "UPDATE document_templates SET nature='vine_phytosanitary_register' WHERE nature='vine_phytosanitary_registry'"
    execute "UPDATE documents SET nature='vine_phytosanitary_register' WHERE nature='vine_phytosanitary_registry'"
    execute "UPDATE attachments SET nature='vine_phytosanitary_register' WHERE nature='vine_phytosanitary_registry'"
  end

  def down
    # Reverse: Change item document_natures#vine_phytosanitary_registry with {:name=>"vine_phytosanitary_register"}
    execute "UPDATE attachments SET nature='vine_phytosanitary_registry' WHERE nature='vine_phytosanitary_register'"
    execute "UPDATE documents SET nature='vine_phytosanitary_registry' WHERE nature='vine_phytosanitary_register'"
    execute "UPDATE document_templates SET nature='vine_phytosanitary_registry' WHERE nature='vine_phytosanitary_register'"
    # Reverse: Change item document_natures#wine_detention_registry with {:name=>"wine_detention_register"}
    execute "UPDATE attachments SET nature='wine_detention_registry' WHERE nature='wine_detention_register'"
    execute "UPDATE documents SET nature='wine_detention_registry' WHERE nature='wine_detention_register'"
    execute "UPDATE document_templates SET nature='wine_detention_registry' WHERE nature='wine_detention_register'"
    # Reverse: Change item document_natures#wine_bottling_registry with {:name=>"wine_bottling_register"}
    execute "UPDATE attachments SET nature='wine_bottling_registry' WHERE nature='wine_bottling_register'"
    execute "UPDATE documents SET nature='wine_bottling_registry' WHERE nature='wine_bottling_register'"
    execute "UPDATE document_templates SET nature='wine_bottling_registry' WHERE nature='wine_bottling_register'"
    # Reverse: Change item document_natures#wine_manipulation_registry with {:name=>"wine_manipulation_register"}
    execute "UPDATE attachments SET nature='wine_manipulation_registry' WHERE nature='wine_manipulation_register'"
    execute "UPDATE documents SET nature='wine_manipulation_registry' WHERE nature='wine_manipulation_register'"
    execute "UPDATE document_templates SET nature='wine_manipulation_registry' WHERE nature='wine_manipulation_register'"
    # Reverse: Change item document_natures#phytosanitary_registry with {:name=>"phytosanitary_register"}
    execute "UPDATE attachments SET nature='phytosanitary_registry' WHERE nature='phytosanitary_register'"
    execute "UPDATE documents SET nature='phytosanitary_registry' WHERE nature='phytosanitary_register'"
    execute "UPDATE document_templates SET nature='phytosanitary_registry' WHERE nature='phytosanitary_register'"
    # Reverse: Change item document_natures#land_parcel_registry with {:name=>"land_parcel_register"}
    execute "UPDATE attachments SET nature='land_parcel_registry' WHERE nature='land_parcel_register'"
    execute "UPDATE documents SET nature='land_parcel_registry' WHERE nature='land_parcel_register'"
    execute "UPDATE document_templates SET nature='land_parcel_registry' WHERE nature='land_parcel_register'"
    # Reverse: Change item document_natures#intervention_registry with {:name=>"intervention_register"}
    execute "UPDATE attachments SET nature='intervention_registry' WHERE nature='intervention_register'"
    execute "UPDATE documents SET nature='intervention_registry' WHERE nature='intervention_register'"
    execute "UPDATE document_templates SET nature='intervention_registry' WHERE nature='intervention_register'"
    # Reverse: Change item document_natures#animal_husbandry_registry with {:name=>"animal_husbandry_register"}
    execute "UPDATE attachments SET nature='animal_husbandry_registry' WHERE nature='animal_husbandry_register'"
    execute "UPDATE documents SET nature='animal_husbandry_registry' WHERE nature='animal_husbandry_register'"
    execute "UPDATE document_templates SET nature='animal_husbandry_registry' WHERE nature='animal_husbandry_register'"
    # Reverse: Change item document_natures#vat_registry with {:name=>"vat_register"}
    execute "UPDATE attachments SET nature='vat_registry' WHERE nature='vat_register'"
    execute "UPDATE documents SET nature='vat_registry' WHERE nature='vat_register'"
    execute "UPDATE document_templates SET nature='vat_registry' WHERE nature='vat_register'"
  end
end
