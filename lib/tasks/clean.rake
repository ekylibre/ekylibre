desc "Clean all"
task clean: :environment do
  [:themes, :schema, :annotations, :tests, :rights,
   :parts, :validations, :locales, :code].each do |cleaner|
    Rake::Task["clean:#{cleaner}"].invoke
  end
end
