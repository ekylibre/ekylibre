desc "Cleans code spacing"
task :code do
  files  = []
  Dir.chdir(Rails.root) do
    files += Dir["**/*.rb"]
    files += Dir["**/*.yml"]
    files += Dir["**/*.haml"]
  end
  files.sort!
  for file in files
    source = nil
    File.open(file, "rb") do |f|
      source = f.read
    end

    # source.gsub!(/(\w+)\ +/, '\1 ')
    source.gsub!(/[\ \t]+\n/, "\n")

    File.open(file, "wb") do |f|
      f.write source
    end
  end

end
