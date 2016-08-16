class Call < ActiveRecord::Base
  has_many :messages, class_name: "CallMessage"
end
