module Ekylibre
  # Handles abaci stored in config/abaci
  class Abaci
    def self.load
      @data = CSV.open(abaci_file, headers: true).read
      true
    end
    alias reload load

    def self.abaci_file
      Rails.root.join('config', 'abaci', abaci_name)
    end

    def self.abaci_name(extension = 'csv')
      abacus_name = name.underscore
      name_without_abacus = abacus_name.split('_abacus').first
      "#{name_without_abacus}.#{extension}"
    end
  end
end
