# frozen_string_literal: true

module Categorizable
  extend ActiveSupport::Concern

  CATEGORIES = %w[animal article crop equipment service worker zone].freeze

  CATEGORIES.each do |category|
    define_method "#{category}?" do
      !!type.match(/#{Regexp.quote(category)}/i)
    end
  end
end
