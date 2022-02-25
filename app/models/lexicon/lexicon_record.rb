# frozen_string_literal: true

class LexiconRecord < ActiveRecord::Base
  prepend IdHumanizable
  include Ekylibre::Record::HasShape

  self.abstract_class = true
end
