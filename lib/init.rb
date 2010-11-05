require File.dirname(__FILE__) + '/acts_as_accountable'
require File.dirname(__FILE__) + '/safe_string'
require File.dirname(__FILE__) + '/i18n'
require File.dirname(__FILE__) + '/models'
# require File.dirname(__FILE__) + '/spreet'
require File.dirname(__FILE__) + '/active_record'
require File.dirname(__FILE__) + '/adapters'
require File.dirname(__FILE__) + '/fix_sqlserver'


module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module Quoting
        def quoted_date(value)
          if value.acts_like?(:time) && value.respond_to?(:usec)
            "#{super(value)}.#{sprintf("%03d",value.usec/1000)}"
          else
            "#{super(value)}T00:00:00"
          end
        end
      end
    end
  end

  class Migration
    # It must be "disconnected" from models so it doesn't use Model.table_name
    def self.quoted_table_name(name)
      return ActiveRecord::Base.table_name_prefix.to_s+name.to_s+ActiveRecord::Base.table_name_suffix.to_s
    end
  end

end

module Ekylibre
  @@version = nil
  
  def self.version
    return @@version unless @@version.nil?
    File.open(Rails.root.join("VERSION")) {|f| @@version = f.read.split(',')[1..2].join("::")}
    return @@version
  end  


  # Must return a File/Dir and not a string
  def self.private_directory
    Ekylibre::Application.root.join("private")
  end
end
