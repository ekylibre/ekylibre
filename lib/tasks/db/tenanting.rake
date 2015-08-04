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
