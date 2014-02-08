desc "Removes end spaces"
task :code do
  print " - White spaces: "
  files  = []
  Dir.chdir(Rails.root) do
    files += Dir["Gemfile*"]
    files += Dir["Rakefile"]
    files += Dir["**/*.ru"]
    files += Dir["**/*.rb"]
    files += Dir["**/*.rake"]
    files += Dir["**/*.yml"]
    files += Dir["**/*.haml"]
    files += Dir["**/*.erb"]
    files += Dir["**/*.rjs"]
    files += Dir["**/*.js"]
    files += Dir["**/*.coffee"]
    files += Dir["**/*.scss"]
    files += Dir["**/*.sass"]
    files += Dir["**/*.css"]
  end
  count = 0
  files.sort!
  for file in files
    next if File.directory?(file)
    original = File.read(file)
    source = original.dup

    # source.gsub!(/(\w+)\ +/, '\1 ')
    source.gsub!(/[\ \t]+\n/, "\n")
    # source.gsub!(/\n+\n$/, "\n")

    if source != original
      File.write(file, source)
      count += 1
    end
  end

  puts "#{count.to_s.rjust(3)} files updated"
end
