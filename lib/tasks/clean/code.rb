desc "Removes end spaces"
task :code do
  files  = []
  Dir.chdir(Rails.root) do
    files += Dir["**/*.rb"]
    files += Dir["**/*.rake"]
    files += Dir["**/*.yml"]
    files += Dir["**/*.haml"]
    files += Dir["**/*.js"]
    files += Dir["**/*.coffee"]
    files += Dir["**/*.scss"]
    files += Dir["**/*.css"]
  end
  files.sort!
  for file in files
    original = nil
    File.open(file, "rb") do |f|
      original = f.read
    end
    source = original.dup

    # source.gsub!(/(\w+)\ +/, '\1 ')
    source.gsub!(/[\ \t]+\n/, "\n")
    # source.gsub!(/\n+\n$/, "\n")

    if source != original
      File.open(file, "wb") do |f|
        f.write source
      end
    end
  end

end
