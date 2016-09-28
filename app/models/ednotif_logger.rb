class EdnotifLogger < Ekylibre::Record::Base
  has_many :calls, as: :source
end
