class NomenclatureMigrationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :name

  def generate_migration
    template 'migration.xml', "db/nomenclatures/migrate/#{timestamp}_#{name}.xml"
  end

  private

  def timestamp
    Time.now.getutc.strftime('%Y%m%d%H%M%S')
  end
end
