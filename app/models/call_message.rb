class CallMessage < ActiveRecord::Base
  belongs_to :operation, class_name: 'Call'
  enumerize :nature, in: [:incoming, :outgoing], predicates: true
end
