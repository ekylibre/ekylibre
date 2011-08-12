#!/usr/bin/env ruby

# Copy database.yml like in real case
system("cp -f database.#{ENV['DB']}.yml ../config/database.yml")

# Create Database manually
if ENV['DB'] == 'postgresql'
  system('psql -c "create database ekylibre_test;" -U postgres > /dev/null 2>&1')
elsif ENV['DB'] == 'mysql'
  system('mysql -e "create database ekylibre_test;" > /dev/null 2>&1')
end

