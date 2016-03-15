namespace :clean do
  desc 'Update and sort translation files'
  task locales: :environment do
    Clean::Locales.run!
  end
end
