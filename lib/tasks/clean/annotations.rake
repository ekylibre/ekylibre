namespace :clean do

  desc "Add schema information (as comments) to model files"
  task :annotations => :environment do
    Clean::Annotations.run
  end

end
