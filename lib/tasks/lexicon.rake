# Lexicon tasks
namespace :lexicon do
  desc 'Download, load and activate a lexicon from db/lexicon folder mentionned in .lexicon-version file'
  task load: :environment do
    Ekylibre::Lexicon.load
  end

  desc 'Download and load a lexicon from params mentionned in LEX_VERSION'
  task download: :environment do
    version_name = ENV['LEX_VERSION'] || ENV['lex_version']
    Ekylibre::Lexicon.download(version_name.to_s)
  end

  desc 'Activate a lexicon mentionned in params LEX_VERSION already loaded, keep old lexicon version in DB if params KEEP=true'
  task activate: :environment do
    version_name = ENV['LEX_VERSION'] || ENV['lex_version']
    keep_lexicon_versions = ENV['KEEP'] || ENV['keep'] || false
    Ekylibre::Lexicon.activate(version_name.to_s, keep_lexicon_versions)
  end

end
