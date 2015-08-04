class BordeauxSciencesAgro::ISTEA::JournalsExchanger < ActiveExchanger::Base
  # Create or updates journals from the Istea codes
  def import
    journals = {}
    rows = CSV.read(file, encoding: 'CP1252', col_sep: ';')
    w.count = rows.size

    rows.each do |row|
      unless journal = Journal.find_by(code: row[0])
        journal = Journal.new(code: row[0], currency: 'EUR')
      end
      journal.name = row[1].mb_chars.capitalize
      journal.save!
      w.check_point
    end
  end
end
