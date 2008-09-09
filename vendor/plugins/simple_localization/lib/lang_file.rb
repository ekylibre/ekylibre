require File.dirname(__FILE__) + '/nested_hash'

module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    # The LangFile class is the interface for the Simple Localization plugin to
    # work with the language files. This class takes care of loading a language
    # file and provides a simple way to access its data using the NestedHash
    # class.
    # 
    # = What are language files?
    # 
    # The Simple Localization plugin uses language files to store the data
    # needed for a specific language. These files are built using YAML[http://www.yaml.org/]
    # and are therefore easy to read and write.
    class LangFile
      
      attr_reader :lang_file_dirs, :lang_code, :yaml_parts, :ruby_parts, :data
      
      # Creates a new LangFile object for the language <code>lang_code</code>
      # which looks for source files in the directories specified in
      # <code>lang_file_dirs</code>.
      # 
      #   LangFile.new :en, 'lang_files'
      #   LangFile.new :en, ['lang_files', 'plugins/lang_files', 'some_dir/with_even_more_lang_files']
      # 
      # The first example will look for <code>en*.yml</code> language files
      # which are located in the <code>lang_file</code> directory.
      # 
      # The second example will look for <code>en*.yml</code> language files,
      # too. However not only in the <code>lang_files</code> directory but also
      # in the directories <code>plugins/lang_files</code> and
      # <code>some_dir/with_even_more_lang_files</code>. The language files are
      # loaded in the order the directories are specified. So entries of
      # language files in the <code>some_dir/with_even_more_lang_files</code>
      # directory will overwrite any previous entries with the same name. Adding
      # new keys to the language file goes in reverse order. A new key for
      # <code>en.yml</code> will be added to
      # <code>some_dir/with_even_more_lang_files/en.yml</code>.
      def initialize(lang_code, lang_file_dirs)
        @lang_code, @lang_file_dirs = lang_code.to_sym, Array(lang_file_dirs)
        @yaml_parts, @ruby_parts = [], []
        # Create a new NestedHash but raise an EntryNotFound exception as
        # default action (if no matching key is found).
        @data = NestedHash.new do raise EntryNotFound end
      end
      
      # This method loads the base YAML language file (eg. <code>de.yml</code>)
      # and all other language file parts (eg. <code>de.app.about.yml</code>)
      # extending the language. These parts are sorted after their length
      # (specifity), the shortes first, and then inserted into the language
      # data. At the end the ruby file belonging to the language is loaded (eg.
      # <code>de.rb</code>).
      def load
        @yaml_parts, @ruby_parts = lookup_parts
        @data.clear
        self.yaml_parts_in_loading_order.each do |yaml_part|
          yaml_data = YAML.load_file(yaml_part)
          part_sections = File.basename(yaml_part, '.yml').split('.')
          part_sections.delete_at 0 # delete the 'en' at the beginning
          if part_sections.empty?
            @data.merge! yaml_data
          else
            begin
              target_section = @data[*part_sections]
              raise EntryNotFound unless target_section.respond_to? :merge!
              target_section.merge! yaml_data
            rescue EntryNotFound
              @data[*part_sections] = yaml_data
            end
          end
        end
        
        @ruby_parts.each do |ruby_part|
          Kernel.load ruby_part
        end
      end
      
      # Reloads the data from the language file and merges it with the existing
      # data in the memory. In case of a conflict the new entries from the
      # language file overwrite the entries in the memory.
      def reload
        old_data = @data.dup
        self.load
        @data = old_data.merge! @data
      end
      
      # Returns a hash with the meta data of this language (language name,
      # author, date, ect.). Entries not present in the language file will
      # default to +nil+.
      def about
        defaults = {
          :language => nil,
          :author => nil,
          :comment => nil,
          :website => nil,
          :email => nil,
          :date => nil
        }
        
        begin
          self.data['about'] ? defaults.update(self.data['about'].symbolize_keys) : defaults
        rescue EntryNotFound
          defaults
        end
      end
      
      protected
      
      # Just searches for the YAML and Ruby parts. The YAML parts are NOT
      # correctly sorted by this method. The Ruby parts are in proper order.
      # 
      # To sort the YAML parts please use the yaml_parts_in_loading_order or
      # yaml_parts_in_saving_order methods.
      def lookup_parts
        @yaml_parts = ActiveSupport::OrderedHash.new
        @ruby_parts = []
        
        self.lang_file_dirs.each do |lang_file_dir|
          yaml_parts_in_this_dir = Dir.glob(File.join(lang_file_dir, "#{self.lang_code}*.yml")).sort
          @yaml_parts[lang_file_dir] = yaml_parts_in_this_dir.collect {|part| File.basename(part)}
          ruby_part_in_this_dir = File.join(lang_file_dir, "#{self.lang_code}.rb")
          @ruby_parts << ruby_part_in_this_dir if File.exists?(ruby_part_in_this_dir)
        end
        
        [@yaml_parts, @ruby_parts]
      end
      
      # Sorts the specified YAML parts in proper loading order. That means first
      # by directories and then by the specificity of the parts. Specificity is
      # the number of section names contained in the file name of the part. More
      # section names results in a higher specificity.
      def yaml_parts_in_loading_order
        ordered_yaml_parts = []
        @yaml_parts.each do |lang_file_dir, parts_in_this_dir|
          parts_in_this_dir.sort_by{|part| File.basename(part, '.yml').split('.').size}.each do |part|
            ordered_yaml_parts << File.join(lang_file_dir, part)
          end
        end
        ordered_yaml_parts
      end
      
      # Sorts the YAML parts in proper write order. That means they are orderd
      # first by their specificity and then by the language file directory
      # priority.
      def yaml_parts_in_saving_order
        lang_file_dirs_by_parts = ActiveSupport::OrderedHash.new
        @yaml_parts.each do |lang_file_dir, parts_in_this_dir|
          parts_in_this_dir.each do |part|
            lang_file_dirs_by_parts[part] = (lang_file_dirs_by_parts[part] || []) << lang_file_dir
          end
        end
        
        ordered_yaml_parts = []
        lang_file_dirs_by_parts.keys.sort_by{|key| key.split('.').size}.reverse.each do |part|
          lang_file_dirs_by_parts[part].reverse.each do |lang_file_dir|
            ordered_yaml_parts << File.join(lang_file_dir, part)
          end
        end
        
        ordered_yaml_parts
      end
      
    end
    
  end
end
