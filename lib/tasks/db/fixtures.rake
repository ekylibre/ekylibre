namespace :db do
  namespace :fixtures do
    desc 'Write database into fixtures files (removing existing files)'
    task dump: :environment do
      Fixturing.dump(ENV['TENANT'] || ENV['name'] || 'test')
    end

    desc 'Load fixtures files in tenant (removing existing data)'
    task restore: :environment do
      Fixturing.restore(ENV['TENANT'] || ENV['name'] || 'test')
    end

    desc 'Migrate fixtures of tenant'
    task migrate: :environment do
      Ekylibre::Tenant.migrate(ENV['TENANT'] || ENV['name'] || 'test')
    end

    desc 'Load fixtures files in tenant (removing existing data)'
    task reverse: :environment do
      Fixturing.reverse(ENV['TENANT'] || ENV['name'] || 'test', ENV['STEPS'] || 1)
    end

    desc 'There and Back Again like Bilbo'
    task bilbo: [:restore, :dump]

    desc 'Demodulates fixtures to have real ids'
    task demodulate: :environment do
      Fixturing.columnize_keys
    end

    desc 'Modulates fixtures to have human fixtures'
    task modulate: :environment do
      Fixturing.reflectionize_keys
    end
  end
end
