# frozen_string_literal: true

module Templatable
  extend ActiveSupport::Concern

  def full_from(user)
    address = Mail::Address.new user.email
    address.display_name = user.full_name
    address.format
  end

end
