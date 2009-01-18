# = Localized human name method of the Column class
# 
# This file contains code which extends ActiveRecords Column class. The aim is
# to localize the Column#human_name method which is heavily used by scaffold.
# 
# So, wheres the problem? By default the +human_name+ method calls the
# ActiveRecord::Base#human_attribute_name method. The localized_models and
# localized_models_by_lang_file features are overwriting this method to provide
# localized data. However for these overwritten methods to work they need to be
# called on the model class itself (eg. Comment) and not on the Base class.
# 
# Why? Because the localized_models feature only overwrites the
# +human_attribute_name+ method in the model class not in the Base class
# itself. The localized_models_by_lang_file feature overwrites the
# +human_attribute_name+ in the Base class but still needs the name of the
# model class to find the proper section of the language file. When called on
# the Base class the overwritten method has no idea to which model class it
# belongs.
# 
# To solve this we extend the Column class to hold a reference to the model
# class it belongs to. Next on we overwrite the +human_name+ method to call the
# +human_attribute_name+ method on the model class if one is available. The
# last step is to update the Base#columns method which builds the column array
# belonging to a model class. After these columns are defined we just have to
# set their newly added +model_class+ property to the current class.
# 
# This way the two features work like usual and we should get the localized
# data. Even when using scaffold.

module ActiveRecord #:nodoc:
  
  module ConnectionAdapters #:nodoc:
    class Column
      
      attr_accessor :model_class
      
      alias_method :human_name_without_localization, :human_name
      
      # Overwrites the +human_name+ method to call +human_attribute_name+ on
      # the model_class if possible. Falls back to default behaviour if no
      # model class is set (original method renamed to +human_name_without_localization+).
      def human_name
        self.model_class ? self.model_class.human_attribute_name(@name) : human_name_without_localization
      end
      

      # Overwrites the +string_to_date+ method to use the localization file
      # to use a parse model for the dates
      def self.string_to_date(string)
# #       raise Exception.new("string_to_date "+string.to_s)
        return string unless string.is_a?(String)
#        date_array = Date._strptime(string, ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default])
#        raise Exception.new("string_to_date "+string.to_s+' ; '+::Date.strptime(string, ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default]).inspect)
        # treat 0000-00-00 as nil
#        Date.civil(date_array[:year], date_array[:mon], date_array[:mday]) rescue nil
        date = ::Date.strptime(string, ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :db]) rescue nil
        if date.nil?
          date = ::Date.strptime(string, ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default]) rescue nil
        end
#        string.to_date
        date
      end

      def self.string_to_time(string)
        return string unless string.is_a?(String)
        time_hash = Date._strptime(string, ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :db])
        return nil if time_hash.nil?
        index = string.index(/\.\d\d\d\d\d\d/)
        time_hash[:sec_fraction] = string[index+1, index+6] if index;
        time_array = time_hash.values_at(:year, :mon, :mday, :hour, :min, :sec, :sec_fraction)
        # treat 0000-00-00 00:00:00 as nil
        raise Exception.new("string_to_time "+string.to_s+" !!!! "+time_array.inspect)
        Time.send(Base.default_timezone, *time_array) rescue DateTime.new(*time_array[0..5]) rescue nil
      end

      def self.string_to_dummy_time(string)
        return string unless string.is_a?(String)
        return nil if string.empty?
        time_hash = Date._strptime(string, ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default])
        index = string.index(/\.\d\d\d\d\d\d/)
        time_hash[:sec_fraction] = string[index+1, index+6] if index;
        time_array = [2000, 1, 1]
        time_array += time_hash.values_at(:hour, :min, :sec, :sec_fraction)
        Time.send(Base.default_timezone, *time_array) rescue nil
      end


    end
  end
  
  class Base
    
    class << self
      
      alias_method :columns_without_localization, :columns
      
      # Updates the ActiveRecord::Base#columns method (original renamed to
      # +columns_without_localization+) to set the +model_class+ property on
      # every column belonging to this model class. This is necessary for the
      # overwritten Column#human_name method to work.
      def columns
        unless @columns
          columns_without_localization
          @columns.each do |column|
            column.model_class = self
          end
        else
          columns_without_localization
        end
      end
      
    end
    
  end
  
end



# module ActiveSupport #:nodoc:
#   module CoreExtensions #:nodoc:
#     module String #:nodoc:
#       module Conversions

#         def to_time(form = :utc)
#           raise Exception.new(self.inspect)

#           # _strptime retrns Hash
#           date_hash = ::Date._strptime(self, ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default])
#           index = self.index(/\.\d\d\d\d\d\d/)
#           date_hash[:sec_fraction] = string[index+1, index+6] if index;
# #          raise Exception.new(date_hash.class.to_s+'  '+date_hash.inspect.to_s+' ? '+ ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default])
#           # #          ::Time.send(form, *ParseDate.parsedate(self))
#           date_array = [date_hash[:year], date_hash[:mon], date_hash[:mday], date_hash[:hour], date_hash[:min], date_hash[:sec], date_hash[:sec_fractions]]
#            ::Time.send(form, *date_array)
#   #        date_hash = ::Date.strptime(self, ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default])
#    #       raise Exception.new(date_hash.class.to_s+'  '+date_hash.to_s+' ? '+ ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default])
#    #       ::Date.strptime(self, ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default]) rescue nil
#    #       ::Time
#         end

#         def to_date
# #          raise Exception.new(self.inspect)
# #          ::Date.new(*ParseDate.parsedate(self)[0..2])
#           dday = ::Date.today
#           date_hash = ::Date._strptime(self, ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default])
#           puts date_hash.inspect
#           puts(self+' > '+date_hash.class.to_s+' ! '+date_hash.inspect+' ? '+dday.to_s+' § '+ ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default])
#           dday = ::Date.civil(date_hash[:year], date_hash[:mon], date_hash[:mday])
#           puts(self+' > '+date_hash.class.to_s+' ! '+date_hash.inspect+' ? '+dday.to_s+' § '+ ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default])
#           # treat 0000-00-00 as nil
# #          ::Date.civil(date_hash[:year],8,16)
# #          Date.civil(date_hash[:year], date_hash[:mon], date_hash[:mday]) rescue nil
# #          ::Date.civil(date_hash[:year], date_hash[:mon], date_hash[:mday])
# #          dday
#           return dday
#         end

#       end
#     end
#   end
# end


