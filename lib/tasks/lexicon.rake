# Lexicon tasks
namespace :lexicon do
  desc 'Load a lexicon from db/lexicon folder mentionned in .lexicon-version file'
  task load: :environment do
    EkyLexicon.new.load
  end
end
