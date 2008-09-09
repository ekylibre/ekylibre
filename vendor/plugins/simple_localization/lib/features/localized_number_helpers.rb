# = Localized number helpers
# 
# Localizes the number helpers of Rails by loading the default options from the
# language file.
# 
# The only exception here is the +number_to_currency+ helper which is
# reimplemented. This is neccessary in order to overwrite the required strings
# with proper localized ones from the language file.
# 
# == Used sections of the language file
# 
#   numbers:
#     separator: '.'
#     delimiter: ','
#     precision: 3
# 
# The +numbers+ section contains the default options common to most number
# helpers (+number_to_currency+, +number_to_percentage+,
# +number_with_delimiter+ and +number_with_precision+).
# 
#   helpers:
#     number_to_currency:
#       precision: 2
#       unit: '$'
#       order: [unit, main, separator, fraction]
#     number_to_phone:
#       area_code: false
#       delimiter: '-'
#       extension: 
#       country_code: 
# 
# The +number_to_currency+ section contains new default options for the
# +number_to_currency+ helper. In case of a conflict the options you specify
# here will overwrite the options specified in the +numbers+ section.
# 
# The +number_to_phone+ section contains the default options for the
# +number_to_phone+ helper. You can use all options this helper accepts.
# 
# == Notes
# 
# This feature contains code for Rails 1.1.x and 1.2.x in different modules
# (<code>Rails11</code> and <code>Rails12</code>). Code common to all version
# is located in the +RailsCommon+ module. Depending on the running Rails
# version the matching module will be included (see end of file). The
# +RailsCommon+ module will be included afterwards because it uses the version
# depended +number_with_delimiter+ helper.

module ArkanisDevelopment::SimpleLocalization #:nodoc
  module LocalizedNumberHelpers
    
    module Rails12
      
      def number_with_delimiter(number, delimiter = Language[:numbers, :delimiter], separator = Language[:numbers, :separator])
        super number, delimiter, separator
      end
      
    end
    
    module Rails11
      
      def number_with_delimiter(number, delimiter = Language[:numbers, :delimiter])
        super number, delimiter
      end
      
    end
    
    module RailsCommon
      
      def number_to_currency(number, options = {})
        options = Language[:numbers].stringify_keys.update(Language[:helpers, :number_to_currency].stringify_keys).update(options.stringify_keys)
        options = options.stringify_keys
        
        precision, unit, separator, delimiter, order = options.delete('precision'){2},
          options.delete('unit'){'$'},
          options.delete('separator'){'.'},
          options.delete('delimiter'){','},
          options.delete('order'){[:unit, :main, :separator, :fraction]}.collect{|e| e.to_sym}
        separator = "" unless precision > 0
        
        begin
          main, fraction = number_with_precision(number, precision).split(Language[:numbers, :separator])
          order[order.index(:unit)] = unit
          order[order.index(:main)] = number_with_delimiter(main, delimiter)
          order[order.index(:separator)] = separator
          order[order.index(:fraction)] = fraction
          order.join
        rescue
          number
        end
      end
      
      def number_to_percentage(number, options = {})
        options = Language[:numbers].stringify_keys.update(options.stringify_keys)
        super(number, options).gsub Language[:numbers, :separator], options['separator']
      end
      
      def number_to_phone(number, options = {})
        options = Language[:helpers, :number_to_phone].stringify_keys.update(options.stringify_keys)
        super number, options
      end
      
      def number_with_precision(number, precision = Language[:numbers, :precision])
        super(number, precision).gsub '.', Language[:numbers, :separator]
      end
      
    end
    
  end
end

if Rails::VERSION::MAJOR == 1 and Rails::VERSION::MINOR == 1
  ActionView::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::Rails11
else
  ActionView::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::Rails12
end

ActionView::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::RailsCommon