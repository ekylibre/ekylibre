####### Important information ####################
# This file is used to setup a shared extensions #
# within a dedicated schema. This gives us the   #
# advantage of only needing to enable extensions #
# in one place.                                  #
#                                                #
# This task should be run AFTER db:create but    #
# BEFORE db:migrate.                             #
##################################################

rule(/db:all:.+/) do |t|
  task_name = t.name.gsub(':all:', ':')

  Rake::Task[task_name] # Ensures task exists

  excludes = ENV['EXCLUDE'] || ''
  excludes = excludes.split(',')
  excludes << 'default'
  unless ENV['INCLUDE_SYSTEM_DBS']
    excludes << 'production'
    excludes << 'development'
    excludes << 'test'
    excludes << 'db_cluster'
  end

  excludes -= (ENV['INCLUDE'] || '').split(',')

  databases = Rails.configuration.database_configuration

  databases.each do |database, _config|
    next if excludes.include? database

    `rake #{task_name} RAILS_ENV=#{database}`
  end
end
