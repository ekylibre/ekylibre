module ActiveRecord

  class Migration
    # It must be "disconnected" from models so it doesn't use Model.table_name
    def self.quoted_table_name(name)
      return ActiveRecord::Base.table_name_prefix.to_s+name.to_s+ActiveRecord::Base.table_name_suffix.to_s
    end
  end

end
