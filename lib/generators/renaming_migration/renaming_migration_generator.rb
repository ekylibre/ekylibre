class RenamingMigrationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :old_name
  argument :new_name
  argument :procedure_name

  def generate_renaming_migration
    return puts "Procedure does not exists, stopping..." unless File.file? procedure_path(procedure_name)
    template 'migration.rb', "db/migrate/#{timestamp}_rename_#{old_name}_to_#{new_name}_in_#{procedure_name}_procedure.rb"
    gsub_procedure(procedure_name, old_name, new_name)
  end

  private

  def gsub_procedure(name, old_name, new_name)
    path = procedure_path(name)
    gsub_file path, /(<(?!procedure|handler)\w* name=)"(#{old_name})"/, "\\1\"#{new_name}\""
  end

  def procedure_path(name)
    File.join(destination_root, 'config', 'procedures', "#{procedure_name}.xml")
  end

  def timestamp
    Time.now.getutc.strftime('%Y%m%d%H%M%S')
  end
end
