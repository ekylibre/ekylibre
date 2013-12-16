module Abax
  include Nomen

  class << self

    # Returns the root of the abaci
    def root
      Rails.root.join("config", "abaci")
    end

  end
end
