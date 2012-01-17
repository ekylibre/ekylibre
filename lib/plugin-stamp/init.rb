# require 'userstamp'
require 'migration'

# ActiveRecord::Base.send(:include, Stamp::Userstamp)
ActiveRecord::Schema.send(:include, Stamp::Schema)
ActiveRecord::Migration.send(:include, Stamp::Migration)


module ActiveRecord
  class Base


    def merge(object)
      raise Exception.new("Unvalid object to merge: #{object.class}. #{self.class} expected.") if object.class != self.class
      reflections = self.class.reflections.collect{|k,v|  v if v.macro==:has_many}.compact
      ActiveRecord::Base.transaction do
        for reflection in reflections
          reflection.class_name.constantize.update_all({reflection.foreign_key=>self.id}, {reflection.foreign_key=>object.id})
        end
        object.delete
      end
      return self
    end

    def has_dependencies?
      
    end


  end
end

