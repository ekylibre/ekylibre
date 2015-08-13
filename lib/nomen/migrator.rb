module Nomen
  module Migrator
    autoload :Model, 'nomen/migrator/model'


    def self.each_reflection(options = {})
      Ekylibre::Record::Base.descendants.each do |klass|
        klass.nomenclature_reflections.each do |_name, reflection|
          next if reflection.model.superclass != Ekylibre::Record::Base
          next if options[:nomenclature] and options[:nomenclature].to_s != reflection.nomenclature
          yield reflection
        end
      end
    end

  end
end
