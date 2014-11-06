namespace :clean do

  desc "Add schema information (as comments) to model files"
  task :annotations => :environment do
    Clean::Annotations.run
  end

  namespace :annotations do

    desc "Add schema information (as comments) to models only"
    task :models => :environment do
      Clean::Annotations.run(only: :models)
    end

    desc "Add schema information (as comments) to fixtures only"
    task :fixtures => :environment do
      Clean::Annotations.run(only: :fixtures)
    end

    desc "Add schema information (as comments) to model tests only"
    task :model_tests => :environment do
      Clean::Annotations.run(only: :model_tests)
    end

  end

end
