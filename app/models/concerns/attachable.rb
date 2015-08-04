module Attachable
  extend ActiveSupport::Concern

  included do
    has_many :attachments, as: :resource
  end
end
