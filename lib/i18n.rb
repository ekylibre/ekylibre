module Ekylibre
  module I18n
    module ContextualHelpers

      def tc(*args)
        args[0] = contextual_scope+'.'+args[0].to_s
        ::I18n.translate(*args)
#        contextual_scope.inspect
      end

      def tg(*args)
        args[0] = 'general.'+args[0].to_s
        ::I18n.translate(*args)
#        contextual_scope.inspect
      end
      
      def lc(*args)
        tc(*args)+'~'
      end

      private

      def contextual_scope
        app_dirs = '(helpers|controllers|views|models)'
        latest_app_file = caller.detect { |level| level =~ /.*\/app\/#{app_dirs}\/[^\.\.]/ }
        return '' unless latest_app_file
        latest_app_file.split(/(\/app\/|\.)/)[2].gsub('/','.').gsub(/(_controller$|_helper$|_observer$)/,'')
      end

#       def contextual_scope
#         stack_to_analyse = caller
#         app_dirs = '(helpers|controllers|views|models)'
#         latest_app_file = stack_to_analyse.detect { |level| level =~ /.*\/app\/#{app_dirs}\/[^\.\.]/ }
#         return '' unless latest_app_file
#         path = latest_app_file.match(/([^:]+):\d+.*/)[1]
#         dir, file = path.match(/.*\/app\/#{app_dirs}\/(.+)#{Regexp.escape(File.extname(path))}$/)[1, 2]
#         scope = [dir] + file.split('/')
#         case dir
#         when 'controllers'
#           scope.last.gsub! /_controller$/, ''
#         when 'helpers'
#           scope.last.gsub! /_helper$/, ''
#         when 'views'
#           scope.last.gsub! /(^_|\..*$)/, ''
#         when 'models'
#           scope.last.gsub! /_observer$/, ''
#         end
#         scope.join "."
#       end


    end

  end
end

ActionController::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActionController::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActionView::Base.send :include, Ekylibre::I18n::ContextualHelpers



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
