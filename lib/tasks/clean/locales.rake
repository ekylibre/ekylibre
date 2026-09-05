namespace :clean do
  desc 'Update and sort translation files (set DRY_RUN=true to preview without writing)'
  task locales: :environment do
    Clean::Locales.run!(dry_run: ENV['DRY_RUN'].to_s.downcase == 'true')
  end
end
