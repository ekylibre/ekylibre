####### Important information ####################
# This file is used to setup a shared extensions #
# within a dedicated schema. This gives us the   #
# advantage of only needing to enable extensions #
# in one place.                                  #
#                                                #
# This task should be run AFTER db:create but    #
# BEFORE db:migrate.                             #
##################################################

namespace :db do
  desc 'Also create shared extensions schemas'
  task extensions: :environment do
    Ekylibre::Schema.setup_extensions
  end

  if Rails.env.development?
    task reinit: :environment do
      schema_whitelist = %w[information_schema postgis].freeze
      schemas = ApplicationRecord.connection
                                 .execute("SELECT schema_name FROM information_schema.schemata")
                                 .to_a
                                 .map { |h| h['schema_name'] }
                                 .reject { |schema| schema_whitelist.include?(schema) || schema =~ /^pg_/ || schema =~ /^lexicon/ }

      schemas.each do |schema|
        ApplicationRecord.connection.execute("DROP SCHEMA \"#{schema}\" CASCADE")
      end

      ApplicationRecord.connection.execute("CREATE SCHEMA \"public\"")

      Rake::Task['tenant:clear'].invoke
      Rake::Task['db:migrate'].invoke
    end
  end
end

Rake::Task['db:create'].enhance do
  Rake::Task['db:extensions'].invoke
end

Rake::Task['db:drop'].enhance do
  Rake::Task['tenant:clear'].invoke
end

Rake::Task['db:test:purge'].enhance do
  Rake::Task['db:extensions'].invoke
end
