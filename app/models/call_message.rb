class CallMessage < ActiveRecord::Base
  belongs_to :operation, class_name: 'Call'
end
