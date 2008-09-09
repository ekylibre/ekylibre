# = Localized model attributes
#
# Extends ActiveRecord models to provide localized accessors for their attributes. They can simply be
# used by prefixing the attribute name with +localized_+. E.g., assuming a model +Employee+ has the
# attributes +birthday+, +salary+ and +name+ and the current language is +de+, the localized attributes can be
# used like this:
#
#   pete = Employee.new(:birthday => Date(1972, 8, 2), :salary => 2200.9, :name => 'Peter')
#   pete.localized_birthday                # => "08.02.1972"
#   pete.localized_birthday = "11.03.1980" # => "1980-03-11"
#   pete.localized_salary                  # => "2.200,9"
#   pete.localized_salary = "3000,50"      # => 3000.5
#
# This enables you to use the +localized_+ attributes in your form helpers, allowing transparent
# localized input of dates and numbers.
#
# == Used sections of the language file
#
# This feature uses the same sections from the lanuage file as do the localized_date_and_time and
# localized_number_helpers features. For date conversions, the +attributes+ date format from the +dates+
# section is used.

# Load localized_date_and_time and localized_number_helpers features required for conversions.
require "#{File.dirname(__FILE__)}/localized_date_and_time.rb"
require "#{File.dirname(__FILE__)}/localized_number_helpers.rb"

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedModelAttributes
    def self.included(base)
      base.class_eval do
        include(InstanceMethods)
        attribute_method_suffix '_localized', '_localized='
      end
    end

    class Helper
      include Singleton
      include ActionView::Helpers::NumberHelper

      if Rails::VERSION::MAJOR == 1 and Rails::VERSION::MINOR == 1
        include LocalizedNumberHelpers::Rails11
      else
        include LocalizedNumberHelpers::Rails12
      end
    end

    module InstanceMethods
      private
        def attribute_localized(attribute_name)
          attribute_value = send(attribute_name)
          column = self.class.columns_hash[attribute_name]

          case column.type
            when :date: localize_date(attribute_value)
            when :datetime: localize_datetime(attribute_value)
            when :float, :integer: localize_number(attribute_value)
            when :decimal: localize_number(attribute_value, column.scale)
            else attribute_value
          end
        end

        def attribute_localized=(attribute_name, new_attribute_value)
          send "#{attribute_name}=", case self.class.columns_hash[attribute_name].type
            when :date: parse_localized_date(new_attribute_value)
            when :datetime: parse_localized_datetime(new_attribute_value)
            when :float: parse_localized_number(new_attribute_value, :to_f)
            when :decimal: parse_localized_number(new_attribute_value, :to_d)
            when :integer: parse_localized_number(new_attribute_value, :to_i)
            else new_attribute_value
          end
        end

        def parse_localized_date(loc_date)
          return if loc_date.blank?
          (Date.strptime(loc_date, Language[:dates, :date_formats, :attributes]))
        end

        def parse_localized_datetime(loc_date)
          return if loc_date.blank?
          (DateTime.strptime(loc_date, Language[:dates, :time_formats, :attributes])).to_time
        end

        def parse_localized_number(loc_number, type_cast)
          return if loc_number.blank?
          loc_number.to_s.gsub(Language[:numbers, :delimiter], '').gsub(Language[:numbers, :separator], '.').send(type_cast)
        end

        def localize_date(date)
          return if date.blank?
          date.to_formatted_s(:attributes)
        end

        def localize_datetime(datetime)
          return if datetime.blank?
          datetime.to_formatted_s(:attributes)
        end

        def localize_number(number, precision = nil)
          return if number.blank?
          number = Helper.instance.number_with_precision(number, precision) if precision
          Helper.instance.number_with_delimiter(number)
        end
    end
  end
end

ActiveRecord::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedModelAttributes
