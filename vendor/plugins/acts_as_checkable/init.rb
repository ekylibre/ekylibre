require 'acts_as_checkable' unless defined?(ActiveRecord::Acts::Checkable)
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Checkable)
