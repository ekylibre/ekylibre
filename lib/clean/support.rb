module Clean
  module Support
    class << self
      def set_search_path!
        Ekylibre::Tenant.reset_search_path!
      end

      def exp(hash, *keys)
        options = keys.extract_options!
        name = keys.last
        if value = rec(hash, *keys)
          return "#{name}: " + yaml_value(value)
        else
          return "# #{name}: " + yaml_value(options[:default] || name.to_s.humanize)
        end
      end

      def rec(hash, *keys)
        key = keys.first
        if hash.is_a?(Hash)
          return rec(hash[key], *keys[1..-1]) if keys.count > 1
          return hash[key]
        end
        nil
      end

      def hash_to_yaml(hash, depth = 0)
        code = "\n"
        x = hash.to_a.sort { |a, b| a[0].to_s.gsub('_', ' ').strip <=> b[0].to_s.gsub('_', ' ').strip }
        x.each_index do |i|
          k = x[i][0]
          v = x[i][1]
          code += '  ' * depth + k.to_s + ':' + (v.is_a?(Hash) ? hash_to_yaml(v, depth + 1) : ' ' + yaml_value(v)) + (i == x.size - 1 ? '' : "\n") if v
        end
        code
      end

      def yaml_to_hash(filename)
        hash = YAML.load(IO.read(filename).gsub(/^(\s*)no:(.*)$/, '\1__no_is_not__false__:\2'))
        deep_symbolize_keys(hash)
      end

      def hash_sort_and_count(hash, depth = 0)
        hash ||= {}
        code = ''
        count = 0
        for key, value in hash.sort { |a, b| a[0].to_s <=> b[0].to_s }
          if value.is_a? Hash
            scode, scount = hash_sort_and_count(value, depth + 1)
            code += '  ' * depth + key.to_s + ":\n" + scode
            count += scount
          else
            code += '  ' * depth + key.to_s + ': ' + yaml_value(value, depth + 1) + "\n"
            count += 1
          end
        end
        [code, count]
      end

      def hash_count(hash)
        count = 0
        for key, value in hash
          count += (value.is_a?(Hash) ? hash_count(value) : 1)
        end
        count
      end

      def sort_yaml_file(filename, log = nil)
        yaml_file = Rails.root.join('config', 'locales', ::I18n.locale.to_s, "#{filename}.yml")
        # translation = hash_to_yaml(yaml_to_hash(file)).strip
        translation, total = hash_sort_and_count(yaml_to_hash(yaml_file))
        File.open(yaml_file, 'wb') do |file|
          file.write translation.strip
        end
        count = 0
        log.write "  - #{(filename.to_s + '.yml:').ljust(20)} #{(100 * (total - count) / total).round.to_s.rjust(3)}% (#{total - count}/#{total})\n" if log
        total
      end

      def deep_symbolize_keys(hash)
        hash.inject({}) do |result, (key, value)|
          value = deep_symbolize_keys(value) if value.is_a? Hash
          key = :no if key.to_s == '__no_is_not__false__'
          result[(key.to_sym rescue key) || key] = value
          result
        end
      end

      def yaml_value(value, depth = 0)
        if value.is_a?(Array)
          '[' + value.collect { |x| yaml_value(x) }.join(', ') + ']'
        elsif value.is_a?(Symbol)
          ':' + value.to_s
        elsif value.is_a?(Hash)
          hash_to_yaml(value, depth + 1)
        elsif value.is_a?(Numeric)
          value.to_s
        else
          # "'"+value.to_s.gsub("'", "''")+"'"
          '"' + value.to_s.gsub("\u00A0", '\\_') + '"'
        end
      end

      def hash_diff(hash, ref, depth = 0, mode = nil)
        hash ||= {}
        ref ||= {}
        keys = (ref.keys + hash.keys).uniq.sort { |a, b| a.to_s.gsub('_', ' ').strip <=> b.to_s.gsub('_', ' ').strip }
        code = ''
        count = 0
        total = 0
        for key in keys
          h = hash[key]
          r = ref[key]
          # total += 1 unless r.is_a? Hash
          if r.is_a?(Hash) && (h.is_a?(Hash) || h.nil?)
            scode, scount, stotal = hash_diff(h, r, depth + 1, mode)
            code << '  ' * depth + key.to_s + ":\n" + scode
            count += scount
            total += stotal
          elsif r && h.nil?
            code << '  ' * depth + '# ' + key.to_s + ': ' + (mode == :humanize ? key.to_s.humanize : yaml_value(r, depth + 1)) + "\n"
            count += 1
            total += 1
          elsif r && h && r.class == h.class
            code << '  ' * depth + key.to_s + ': ' + yaml_value(h, depth + 1) + "\n"
            total += 1
          elsif r && h && r.class != h.class
            code << '  ' * depth + key.to_s + ': ' + (yaml_value(h, depth) + "\n").gsub(/\n/, " #? #{r.class.name} excepted (#{h.class.name + ':' + h.inspect})\n")
            total += 1
          elsif h && r.nil?
            code << '  ' * depth + key.to_s + ': ' + (yaml_value(h, depth) + "\n").to_s.gsub(/\n/, " #?\n")
          elsif r.nil?
            code << '  ' * depth + key.to_s + ": #?\n"
          end
        end
        [code, count, total]
      end

      def look_for_labels(*paths)
        list = []
        for path in paths.flatten
          for file in Dir.glob(path)
            source = File.read(file)
            source.gsub(/(\'[^\']+\'|\"[^\"]+\"|\:\w+)\.(tl|th)/) do |exp|
              exp.gsub!(/\.tl\z/, '')
              exp.gsub!(/\A\:/, '')
              exp = exp[1..-2] if exp =~ /\A\'.*\'\z/ || exp =~ /\A\".*\"\z/
              exp.gsub!(/\#\{[^\}]+\}/, '*')
              list << exp
            end
            source.gsub(/(\'labels\.[^\']+\'|\"labels\.[^\"]+\")\.t/) do |exp|
              exp.gsub!(/\.t\z/, '')
              exp = exp[1..-2] if exp =~ /\A\'.*\'\z/ || exp =~ /\A\".*\"\z/
              exp.gsub!(/\Alabels\./, '')
              exp.gsub!(/\#\{[^\}]+\}/, '*')
              list << exp
            end
            source.gsub(/(tg|tl|field_set|cell|cobble|subheading)\s*\(?\s*(\:?\'[^\w+\.]+\'|\:?\"[^\"]+\"|\:\w+)\s*(\)|\,|\z|\s+do)/) do |exp|
              exp = exp.split(/[\s\(\)\:\'\"\,]+/)[1]
              exp.gsub!(/\#\{[^\}]+\}/, '*')
              list << exp
            end
          end
        end
        list += Ekylibre::Navigation.parts.collect { |p| p.index.keys }.flatten.compact.map(&:to_s)
        list += Ekylibre::Navigation.parts.map(&:name).map(&:to_s)

        # list += actions_hash.delete_if{|k,v| k == "backend/dashboards" }.values.flatten.uniq.delete_if{|a| a =~ /\Alist\_/ }
        list.delete_if { |l| l == '*' || l.underscore != l }.uniq.sort
      end

      def look_for_rest_actions
        actions_hash.delete_if { |k, _v| k == 'backend/dashboards' }.values.flatten.uniq.delete_if { |a| a =~ /\Alist\_/ }
      end

      def look_for_notifications(*paths)
        list = []
        for path in paths.flatten
          for file in Dir.glob(path)
            source = File.read(file)
            source.gsub(/notify(_error|_warning|_success)?(_now)?(\(\s*|\s+)\:\w+/) do |exp|
              list << exp.split(/\:/)[1].to_sym
            end
            source.gsub(/\:\w+\.tn/) do |exp|
              list << exp[1..-4].to_sym
            end
          end
        end
        list.sort
      end

      def text_found?(exp, *paths)
        for path in paths
          for file in Dir.glob(path)
            return true if File.read(file) =~ exp
          end
        end
        false
      end

      def default_action_title(controller_path, action_name)
        action_name = action_name.to_sym unless action_name.is_a?(Symbol)
        controller_name = controller_path.split('/').last
        text = if action_name == :index
                 controller_name.humanize
               elsif action_name == :show
                 controller_name.humanize.singularize + ': %{name}'
               elsif [:new].include? action_name
                 "#{action_name} #{controller_name.humanize.singularize}".humanize
               elsif [:list, :import, :export].include? action_name
                 "#{action_name} #{controller_name}".humanize
               else
                 "#{action_name} #{controller_name.humanize.singularize}: %{name}".humanize
               end
        text
      end

      # Lists all actions of all controller by loading them and list action_methods
      def actions_hash
        controllers = controllers_in_file
        ref = HashWithIndifferentAccess.new
        for controller in controllers_in_file
          ref[controller.controller_path] = controller.action_methods.to_a.sort.delete_if { |a| a.to_s =~ /\A\_/ }
        end
        ref
      end

      # Lists all models that inherits of ActiveRecord but are not system
      def models_in_file
        Dir.glob(Rails.root.join('app', 'models', '*.rb')).each { |file| require file }
        ObjectSpace
          .each_object(Class)
          .select { |klass| klass < ActiveRecord::Base }
          .select { |x| !x.name.match(/\AActiveRecord\:\:/) && !x.abstract_class? && !x.name.match(/\AHABTM\_/) }
          .uniq
          .sort { |a, b| a.name <=> b.name }
      end

      # Lists all controller that inherits of ApplicationController included
      def controllers_in_file
        Dir.glob(Rails.root.join('app', 'controllers', '**', '*.rb')).each { |file| require file }
        ObjectSpace
          .each_object(Class)
          .select { |klass| klass < ActionController::Base }
          .sort { |a, b| a.name <=> b.name }
      end

      # Lists helpers paths
      def helpers_in_file
        dir = Rails.root.join('app', 'helpers')
        list = Dir.glob(dir.join('**', '*.rb')).collect do |h|
          Pathname.new(h).relative_path_from(dir).to_s[0..-4]
        end
        list
      end

      # Lists jobs paths
      def jobs_in_file
        dir = Rails.root.join('app', 'jobs')
        list = Dir.glob(dir.join('**', '*.rb')).collect do |h|
          Pathname.new(h).relative_path_from(dir).to_s[0..-4]
        end
        list
      end
    end
  end
end
