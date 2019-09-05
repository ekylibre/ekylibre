namespace :lexicon do
  task clear: :environment do
    Lexicon.clear!
  end

  task load: :environment do
    Lexicon.reload!
  end

  task disable: :environment do
    Lexicon.disable!
  end

  task enable: :environment do
    Lexicon.enable!
  end

  task upgrade: :environment do
    Lexicon.reload!
  end
end

# Clear lexicon before migration
task 'db:migrate' => 'lexicon:disable'

# Load lexicon after migration
Rake::Task['db:migrate'].enhance do
  Rake::Task['lexicon:enable'].invoke
end
