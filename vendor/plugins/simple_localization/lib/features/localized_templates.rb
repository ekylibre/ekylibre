# = Localized templates
# 
# This feature extends Rails template handling and allows the use of localized
# templates like <code>index.de.rhtml</code>. The plugin will then pick the
# template matching the currently used language
# (<code>Language#current_language</code>).
# 
# The code for this feature is taken from the Globalize plugin for Rails
# (http://www.globalize-rails.org/) and is slighly modified to avoid naming
# conflicts. The Globalize team deserves all credit for this great solution.
# If you find this feature helpful thank them.
# 
# == Used sections of the language file
# 
# This feature does not use sections from the lanuage file.

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedTemplates
    
    def self.included(base)
      base.class_eval do
        
        alias_method :render_file_without_localization, :render_file
        
        # Name of file extensions which are handled internally in rails. Other types
        # like liquid has to register through register_handler.
        # The erb extension is used to handle .html.erb templates.
        @@native_extensions = /\.(rjs|rhtml|rxml|erb)$/
        
        @@localized_path_cache = {}
    
        def render_file(template_path, use_full_path = true, local_assigns = {})
          @first_render ||= template_path
          
          localized_path, template_extension = locate_localized_path(template_path, use_full_path)
          
          # Delegate templates are picked by the template extension and if
          # use_full_path is true Rails does not search for an extension and so
          # delegate templates won't work. To fix this try to convert the path
          # back to a relative one.
          if use_full_path
            localized_path.gsub!(/#{Regexp.escape('.' + template_extension)}$/, '') if template_extension
            
            # Make this rails edge secure. Edgy uses an array called view_paths
            # to store paths of the view files. Rails 1.2 stors just on path in
            # the @base_path variable.
            if self.respond_to?(:view_paths)
              self.view_paths.each do |view_path|
                localized_path.gsub!(/^#{Regexp.escape(view_path)}\//, '')
              end
            else
              localized_path.gsub!(/^#{Regexp.escape(@base_path)}\//, '')
            end
          end
          
          # don't use_full_path -- we've already expanded the path
          # FALSE: doing this will break delegate templates!
          render_file_without_localization(localized_path, use_full_path, local_assigns)
        end
        
        private
        
        alias_method :path_and_extension_without_localization, :path_and_extension
        
        # Override because the original version is too minimalist
        def path_and_extension(template_path) #:nodoc:
          template_path_without_extension = template_path.sub(@@native_extensions, '')
          [ template_path_without_extension, $1 ]
        end
        
        def locate_localized_path(template_path, use_full_path)
          current_language = Language.current_language
          
          cache_key = "#{current_language}:#{template_path}"
          cached = @@localized_path_cache[cache_key]
          return cached if cached
          
          if use_full_path
            template_path_without_extension, template_extension = path_and_extension(template_path)
            
            if template_extension
              template_file_name = full_template_path(template_path_without_extension, template_extension)
            else
              template_extension = pick_template_extension(template_path).to_s
              template_file_name = full_template_path(template_path, template_extension)
            end
          else
            template_file_name = template_path
            template_extension = path_and_extension(template_path).last
          end
          
          # template_extension is nil if the specified template does not use a
          # template engine (like render :file => ... with a .html, .txt, ect.
          # extension). In this case just pass the template name as it is.
          if template_extension
            pn = Pathname.new(template_file_name)
            dir, filename = pn.dirname, pn.basename('.' + template_extension)
            
            localized_path = dir + "#{filename}.#{current_language}.#{template_extension}"
            
            unless localized_path.exist?
              localized_path = template_file_name
            end
          else
            localized_path = template_file_name
          end
          
          [@@localized_path_cache[cache_key] = localized_path.to_s, template_extension]
        end
        
      end
    end
    
  end
end

ActionView::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedTemplates
