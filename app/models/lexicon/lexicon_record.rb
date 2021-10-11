# frozen_string_literal: true

class LexiconRecord < ActiveRecord::Base
  prepend IdHumanizable

  self.abstract_class = true
end
