module Ekylibre
  module I18n
    module ContextualHelpers

      def tc(*args)
        args[0] = contextual_scope+'.'+args[0].to_s
        ::I18n.translate(*args)
      end

      def tg(*args)
        args[0] = 'general.'+args[0].to_s
        ::I18n.translate(*args)
      end
      
      private

      def contextual_scope
        app_dirs = '(helpers|controllers|views|models)'
        latest_app_file = caller.detect { |level| level =~ /.*\/app\/#{app_dirs}\/[^\.\.]/ }
        return 'eval' unless latest_app_file
        latest_app_file.split(/(\/app\/|\.)/)[2].gsub('/','.').gsub(/(_controller$|_helper$|_observer$)/,'')
      end

    end

  end
end

ActionController::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActionController::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActionView::Base.send :include, Ekylibre::I18n::ContextualHelpers


module ::I18n

  def self.pretranslate(*args)
    res = translate(*args)
    if res.match(/translation\ missing|\(\(/)
      "((("+args[0].to_s.split(".")[-1].upper+")))"
    else
      "'"+res.gsub(/\'/,"''")+"'"
    end
  end

  def self.hardtranslate(*args)
    result = translate(*args)
    return (result.match(/translation\ missing|\(\(\(/) ? nil : result)
  end

end


ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  msg = instance.error_message
  error_class = 'invalid'
  
  if html_tag =~ /<(input|textarea|select)[^>]+class=/
    class_attribute = html_tag =~ /class=['"]/
    html_tag.insert(class_attribute + 7, "#{error_class} ")
  elsif html_tag =~ /<(input|textarea|select)/
    first_whitespace = html_tag =~ /\s/
    html_tag[first_whitespace] = " class=\"#{error_class}\" "
  end
  
  html_tag
end







# module ActiveRecord
#   module ConnectionAdapters #:nodoc:
#     # An abstract definition of a column in a table.
#     class Column

#       module Format
#         #        ISO_DATE = /\A(\d{4})-(\d\d)-(\d\d)\z/
#         #        ISO_DATETIME = /\A(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)(\.\d+)?\z/
#       end

#       class << self

#         def string_to_date(string)
#           puts ">> DATE : "+string.inspect
#           return string unless string.is_a?(String)
#           return nil if string.empty?
#           fast_string_to_date(string) || fallback_string_to_date(string)
# #          return Date.new(1789,7,14)
# #          return string unless string.is_a?(String)
# #          date_array = Date._strptime(string, I18n.translate('date.formats.db'))
# #           date_array = Date._strptime(string, '%d/%m/%Y')
# #           raise Exception.new(string.inspect+' # '+date_array.inspect)
# #           # treat 0000-00-00 as nil
# #           #        Date.civil(2006,12,24)
# #           Date.civil(date_array[:year], date_array[:mon], date_array[:mday]) rescue nil
#         end

#         def string_to_time(string)
# #          return string unless string.is_a?(String)
# #          return nil if string.empty?

# #          fast_string_to_time(string) || fallback_string_to_time(string)
#           return Time.now
#         end

#         def string_to_dummy_time(string)
# #          return string unless string.is_a?(String)
# #          return nil if string.empty?

# #          string_to_time "2000-01-01 #{string}"
#           return Time.now
#         end

#         protected

#           def fast_string_to_date(string)
#             if string =~ Format::ISO_DATE
#               new_date $1.to_i, $2.to_i, $3.to_i
#             end
#           end

#           # Doesn't handle time zones.
#           def fast_string_to_time(string)
#             if string =~ Format::ISO_DATETIME
#               microsec = ($7.to_f * 1_000_000).to_i
#               new_time $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, microsec
#             end
#           end

#           def fallback_string_to_date(string)
#             new_date(*::Date._parse(string, false).values_at(:year, :mon, :mday))
#           end

#           def fallback_string_to_time(string)
#             time_hash = Date._parse(string)
#             time_hash[:sec_fraction] = microseconds(time_hash)

#             new_time(*time_hash.values_at(:year, :mon, :mday, :hour, :min, :sec, :sec_fraction))
#           end
#       end

#     end
#   end
# end


# module ActiveSupport #:nodoc:
#   module CoreExtensions #:nodoc:
#     module String #:nodoc:
#       module Conversions

#         def to_time(form = :utc)
#           *date_array = Date._strptime(self, ArkanisDevelopment::SimpleLocalization::Language[:dates, :time_formats, :default])
#           index = self.index(/\.\d\d\d\d\d\d/)
#           *date_array[:sec_fraction] = string[index+1, index+6] if index;
# #          ::Time.send(form, *ParseDate.parsedate(self))
#           ::Time.send(form, *date_array)
#         end

#         def to_date
# #          ::Date.new(*ParseDate.parsedate(self)[0..2])
#           date_array = Date._strptime(self, ArkanisDevelopment::SimpleLocalization::Language[:dates, :date_formats, :default])
#           # treat 0000-00-00 as nil
# #          Date.civil(2004,8,16)
#           Date.civil(date_array[:year], date_array[:mon], date_array[:mday]) rescue nil
#         end
#       end
#     end
#   end
# end


