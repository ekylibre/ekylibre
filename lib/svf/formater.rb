module SVF
  class Formater
    attr_reader :name, :lines

    def initialize(name, file)
      @name = name
      source = YAML.load_file(file)
      @lines = {}
      source['lines'].each do |name, line|
        @lines[name.to_sym] = Line.new(name, line['key'], line['cells'], line['children'], line['to'])
      end
      @root = SVF.occurrencify(source['root'])
    end

    def generate
      code = "module #{@name.to_s.classify}\n"

      code << "  module Lines\n\n"
      @lines.values.each do |element|
        code << compile_element(element).gsub(/^/, '    ')
      end
      code << "  end\n\n"

      code << "  class Base\n"
      code << '    attr_accessor ' + @root.collect { |x| ":#{x.name}" }.join(', ') + "\n\n"
      code << "    def self.parse_line(line, _number)\n"
      code << "      return nil if line.nil?\n"
      # code << "      puts line.gsub(/\\r\\n$/, '').yellow + '$'.green\n"
      code << '      '
      @lines.values.each do |line|
        code << "if line =~ /^#{line.key.gsub(' ', '\\ ')}/\n"
        line_code = nil
        if line.cells.any?
          line_code = "begin\n"
          line_code << "  #{line.class_name(@name)}.new(\n" + line.cells.map do |c|
            "  #{c.parse_value}"
          end.join(",\n") + "\n)\n"
          line_code << "rescue Exception => e\n"
          line_code << "  puts \"[Line #\#{_number + 1}] Cannot parse #{line.name}: \" + line.inspect.cyan\n"
          line.cells.each do |c|
            line_code << "  puts '#{c.start.to_s.rjust(3)}:#{c.stop.to_s.rjust(3)}:#{c.name.to_s.rjust(20)}: ' + line[#{c.start}..#{c.stop}].to_s.inspect.cyan\n"
          end
          line_code << "  raise SVF::InvalidSyntax, e.message\n"
          line_code << "end\n"
        else
          line_code = "#{line.class_name(@name)}.new\n"
        end
        code << line_code.dig(4)
        code << '      els'
      end
      code << "e\n"
      code << "        return nil\n"
      code << "      end\n"
      code << "    end\n\n"

      code << "    def self.parse(file)\n"
      code << "      base = Base.new\n"
      code << "      ::File.open(file, 'rb:ISO8859-1') do |f|\n"
      code << "        line_number = 0\n"
      code << parse_code(@root, file: 'f', root: 'base').strip.gsub(/^/, '        ') + "\n"
      code << "      end\n"
      code << "      base\n"
      code << "    end\n\n"

      code << "    # Build file as a string\n"
      code << "    def to_s\n"
      code << "      _string = ''\n"
      code << build_code(@root, variable: '_string', root: 'self').strip.gsub(/^/, '      ') + "\n"
      code << "      _string\n"
      code << "    end\n\n"

      code << "  end\n\n"

      code << "  # Shortcut to parse #{@name.to_s.classify} files\n"
      code << "  def self.parse(file)\n"
      code << "    return Base.parse(file)\n"
      code << "  end\n\n"

      code << "end\n"
      # list = code.split("\n"); list.each_index { |x| puts((x + 1).to_s.rjust(4).yellow + ': ' + list[x].blue) }
      code.gsub(/\ +\n/, "\n")
    end

    def compile_element(element, _depth = 0)
      code = "class #{element.class_name}\n"
      code << '  attr_accessor ' + element.cells.collect { |c| ":#{c.name}" }.join(', ') + "\n" if element.has_cells?
      code << '  attr_accessor ' + element.children.collect { |c| ":#{c.name}" }.join(', ') + "\n" if element.has_children?
      code << "  attr_accessor :text\n" if element.to
      element.cells.select { |c| c.type == :boolean }.each do |bool|
        code << "  alias #{bool.name}? #{bool.name}\n"
      end
      code << '  def initialize(' + element.cells.collect(&:name).join(', ') + ")\n"
      if element.has_cells?
        element.cells.each do |c|
          code << "    @#{c.name} = #{c.name}\n"
        end
      end
      element.children.reject { |c| c.range.max == 1 }.each do |c|
        code << "    @#{c.name} = []\n"
      end
      code << "    @text = ''\n" if element.to
      code << "  end\n"
      code << "\n  def to_s\n"
      unless element.to
        code << "    '#{element.key}' + " + element.cells.collect { |c| c.format_value("@#{c.name}") }.join(' + ') + " + \"\\r\\n\"\n"
      end
      code << "  end\n"
      code << "end\n\n"
      code
    end

    def parse_code(siblings = [], options = {})
      parents = options[:parents] || []
      all_parents = options[:all_parents] || []
      code = ''
      code << "line = parse_line(#{options[:file]}.gets, line_number)\n"
      code << "line_number += 1\n"
      code << "while line\n"
      code << '  '
      siblings.each do |sibling|
        line = @lines[sibling.line]
        full_name = "#{options[:root].to_s + '.' if options[:root]}#{sibling.name}"
        code << "if line.is_a?(#{line.class_name(@name)})\n"
        new_line = (line.has_children? ? sibling.line : 'line')
        code << "    #{sibling.line} = line\n" if line.has_children?
        code << (sibling.range.max == 1 ? "    #{full_name} = #{new_line}\n" : "    #{full_name} << #{new_line}\n")
        if line.to
          code << "    line = #{options[:file]}.gets\n"
          code << "    line_number += 1\n"
          code << "    while !line.nil? && line =~ /^#{line.to.gsub(/\ /, '\\ ')}\\ *$/\n"
          code << "      #{full_name}.text << line\n"
          code << "      line = #{options[:file]}.gets\n"
          code << "      line_number += 1\n"
          code << "    end\n"
        end
        if line.has_children?
          code << parse_code(line.children, file: options[:file], root: sibling.line, parents: siblings, all_parents: siblings + all_parents).strip.gsub(/^/, '    ') + "\n"
        else
          code << "    line = parse_line(#{options[:file]}.gets, line_number)\n"
          code << "    line_number += 1\n"
        end
        code << '  els'
      end
      if !parents.empty?

        code << 'if [' + all_parents.collect { |s| raise([s, s.line].inspect) if @lines[s.line].nil?; @lines[s.line].class_name(@name) }.sort.join(', ') + "].include?(line.class)\n"
        # code << "if "+all_parents.collect{|s| "line.is_a?(#{@lines[s.line].class_name(@name)})"}.join(" or ")+"\n"
        code << "    break\n"
        code << "  else\n"
        rep = '[#{__LINE__}]'
        code << "    raise StandardError, \"#{rep} Unexpected element at line \#{line_number}: \#{line.class.name}:\#{line.inspect}\"\n"
      else
        code << "e\n"
        code << "    raise StandardError, \"#{rep} Unexpected element at line \#{line_number}: \#{line.class.name}:\#{line.inspect}\"\n"
      end
      code << "  end\n"

      code << "end\n"
      code
    end

    def build_code(siblings, options = {})
      code = ''
      var = options[:variable]
      root = options[:root].to_s
      siblings.each do |sibling|
        line = @lines[sibling.line]
        full_name = "#{root + '.' if options[:root]}#{sibling.name}"
        code << "#{sibling.name} = #{full_name}\n"
        code << "if #{sibling.name}\n"
        if sibling.range.max == 1
          code << "  #{var} << #{sibling.name}.to_s\n"
          code << build_code(line.children, variable: var, root: sibling.line).strip.gsub(/^/, '  ') + "\n" if line.has_children?
        else
          code << "  #{sibling.name}.each do |#{sibling.line}|\n"
          code << "    #{var} << #{sibling.line}.to_s\n"
          code << build_code(line.children, variable: var, root: sibling.line).strip.gsub(/^/, '    ') + "\n" if line.has_children?
          code << "  end\n"
        end
        code << "end\n"
      end
      code
    end
  end
end
