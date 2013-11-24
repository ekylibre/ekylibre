module Taskable
  extend ActiveSupport::Concern

  included do
    belongs_to :operation
  end
end
