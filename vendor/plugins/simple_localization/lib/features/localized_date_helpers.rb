# = Localized date helpers
# 
# Localizes the +date_select+ helper by loading the default options from the
# language file. The +distance_of_time_in_words+ however can only be localized
# by reimplementing it here. Every result is based on a string from the
# language file.
# 
# Many other helpers are based on these two so the localization of these
# helpers should localize many other.
# 
# == Used sections of the language file
# 
# This feature uses the +date_select+ and +distance_of_time_in_words+ section
# within the +helpers+ section:
# 
#   helpers:
#     date_select:
#       order: [:year, :month, :day]
#     distance_of_time_in_words:
#       less than 5 seconds: less than 5 seconds
#       less than 10 seconds: less than 10 seconds
#       less than 20 seconds: less than 20 seconds
#       less than a minute: less than a minute
#       1 minute: 1 minute
#       half a minute: half a minute
#       n minutes: %i minutes
#       about 1 hour: about 1 hour
#       about n hours: about %i hours
#       1 day: 1 day
#       n days: %i days
#       about 1 month: about 1 month
#       n months: %i months
#       about 1 year: about 1 year
#       over n years: over %i years
# 
# The +date_select+ section contains new default options for the +date_select+
# helper so you can overwrite all options this helper accepts. The
# +distance_of_time_in_words+ section contains a map of translated strings used
# to build the output of this helper.

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedDateHelpers
    
    # Localizes the +date_select+ helper by loading the default options from
    # the language file.
    def date_select(object_name, method, options = {})
      options = Language[:helpers, :date_select].symbolize_keys.update(options)
      super object_name, method, options
    end
    
    # Localizes the +distance_of_time_in_words+ helper by reimplementing it and
    # loading the strings from the language file.
    def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      distance_in_minutes = (((to_time - from_time).abs)/60).round
      distance_in_seconds = ((to_time - from_time).abs).round
      
      lang = Language[:helpers, :distance_of_time_in_words]
      
      case distance_in_minutes
        when 0..1
          return (distance_in_minutes == 0) ? lang['less than a minute'] : lang['1 minute'] unless include_seconds
          case distance_in_seconds
            when 0..4   then lang['less than 5 seconds']
            when 5..9   then lang['less than 10 seconds']
            when 10..19 then lang['less than 20 seconds']
            when 20..39 then lang['half a minute']
            when 40..59 then lang['less than a minute']
            else             lang['1 minute']
          end
        
        when 2..44           then format(lang['n minutes'], distance_in_minutes)
        when 45..89          then lang['about 1 hour']
        when 90..1439        then format(lang['about n hours'], (distance_in_minutes.to_f / 60.0).round)
        when 1440..2879      then lang['1 day']
        when 2880..43199     then format(lang['n days'], (distance_in_minutes / 1440).round)
        when 43200..86399    then lang['about 1 month']
        when 86400..525959   then format(lang['n months'], (distance_in_minutes / 43200).round)
        when 525960..1051919 then lang['about 1 year']
        else
          years = (distance_in_minutes / 525960).round
          format(lang["over #{years} years"] || lang['over n years'], years)
      end
    end
    
  end
end

ActionView::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedDateHelpers