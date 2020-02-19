class RegisteredPhytosanitarySymbol < ActiveRecord::Base
  include Lexiconable

  has_many :risks, class_name: 'RegisteredPhytosanitaryRisk', foreign_key: :risk_code
end
