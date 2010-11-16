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
end
