["", ":thumbnails", ":metadata", ":missing_styles"].each do |suffix|
  Rake::Task["paperclip:refresh#{suffix}"].enhance do
    Ekylibre::Tenant.switch_each do |tenant|
      puts "Refresh#{suffix.gsub(':', ' ')} on #{tenant.to_s.yellow}..."
      Rake::Task["paperclip:refresh#{suffix}"].invoke
    end
  end
end
