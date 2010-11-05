$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/acts/protected'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Protected }
