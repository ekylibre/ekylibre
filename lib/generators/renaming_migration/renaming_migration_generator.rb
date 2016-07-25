class RenamingMigrationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :old_name
  argument :new_name
  argument :procedure_name

  def generate_renaming_migration
    template "migration.rb", "db/migrate/#{timestamp}_rename_#{old_name}_to_#{new_name}_in_#{procedure_name}_procedure.rb"
  end

  private

  def timestamp
    Time.now.getutc.strftime("%Y%m%d%H%M%S")
  end
end
