class RenamingMigrationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :old_name
  argument :new_name
  argument :procedure_name

  def generate_renaming_migration
    return say "Sorry but this generator's execution isn't reversible yet.", :yellow if behavior == :revoke
    return say 'Procedure does not exists, stopping...', :yellow unless File.file? procedure_path
    template 'migration.rb', File.join('db', 'migrate', "#{timestamp}_rename_#{old_name}_to_#{new_name}_in_#{procedure_name}_procedure.rb")
    gsub_procedure
  end

  private

  def gsub_procedure
    path = procedure_path
    gsub_file path, /(<(?!procedure|handler)\w* name=)"(#{old_name})"/, "\\1\"#{new_name}\""
  end

  def procedure_path
    File.join(destination_root, 'config', 'procedures', "#{procedure_name}.xml")
  end

  def timestamp
    Time.now.getutc.strftime('%Y%m%d%H%M%S')
  end
end
