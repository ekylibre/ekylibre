module Attachable
  extend ActiveSupport::Concern

  included do
    has_many :attachments, as: :resource, inverse_of: :resource

    accepts_nested_attributes_for :attachments

  end
end
