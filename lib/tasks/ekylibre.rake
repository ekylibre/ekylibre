# coding: utf-8

def annotate_one_file(file_name, info_block)
  puts "------------------------- "+ file_name.inspect
  unless File.exist?(file_name)
    File.open(file_name, "w") { |f| f.puts "# Generated" }
  end
  if File.exist?(file_name)
    content = File.read(file_name)
    lines = "\nEkylibre - Simple ERP\nCopyright (C) 2009 Brice Texier, Thibaud Mérigon\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n".split(/[\r\n]+/).compact

    for line in lines
      unless line.match(/^\s*$/)
        #  puts line.inspect
        content.gsub!(/^#{line}$/, '#') 
      end
    end
    content.gsub!(/^Copyright.*$/, '#') 
    
    content.gsub!(/\#\n\#\n\s*\n\s*(\n\s*)?\#\n\#/, "#")
    content.gsub!(/\#\n\#\n\s*\n\s*(\n\s*)?\#\n\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")

    # puts content
    # Remove old schema info
    # content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')
    
    
    # Write it back
    File.open(file_name, "wb") { |f| f.puts(content) }
  end
end

desc ""
task :lig do
  models = []
  Dir.chdir("app/models") do 
    models = Dir["**/*.rb"].sort
  end
  
  info =  "\nEkylibre - Simple ERP\nCopyright (C) 2009 Brice Texier, Thibaud Mérigon\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n"
  models.each do |m|
    cn = m.sub(/\.rb$/,'')
    class_name = m.sub(/\.rb$/,'').camelize
    begin
      
      #      klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
      #      if klass < ActiveRecord::Base && !klass.abstract_class?
      puts "Annotating #{class_name}"
      
      model_file_name = File.join("app/models", cn + ".rb")
      annotate_one_file(model_file_name, info)
      
      fixture_file_name = File.join("test/fixtures", cn.pluralize + ".yml")
      annotate_one_file(fixture_file_name, info)

      unit_file_name = File.join("test/unit", cn + "_test.rb")
      annotate_one_file(unit_file_name, info)

      #      else
      #        puts "Skipping #{class_name}"
      #      end
    rescue Exception => e
      puts "Unable to annotate #{class_name}: #{e.message}"
    end
  end

end

