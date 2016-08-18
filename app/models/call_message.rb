# Class representing any message linked to APIs in DB, whether ours or others.
class CallMessage < Ekylibre::Record::Base
  belongs_to :operation, class_name: 'Call'
  enumerize :nature, in: [:incoming, :outgoing], predicates: true
end
