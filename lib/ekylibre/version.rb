module Ekylibre
  real_version = File.read(Rails.root.join('VERSION'))
  ekylibre_version = real_version.split(" - ").first if real_version.include?('-')
  VERSION = ekylibre_version.freeze
end
