namespace :clean do
  desc 'Removes end spaces'
  task :code do
    print ' - White spaces: '
    files = []
    dirs = '{app,config,db,doc,lib,plugins,public,test,vendor}'
    extensions = '{ru,rb,rake,treetop,yml,xml,txt,rdoc,md,haml,erb,rjs,js,coffee,scss,sass,css}'
    Dir.chdir(Rails.root) do
      files += Dir['Gemfile*']
      files += Dir['Rakefile']
      files += Dir['bin/*']
      files += Dir["#{dirs}/**/*.#{extensions}"].delete_if do |p|
        p =~ /\Adb\/first_runs\// || p =~ /\Atest\/fixture-files\//
      end
    end
    log = File.open(Rails.root.join('log', 'clean-code.log'), 'wb')
    log.write "White spaces:\n"
    count = 0
    files.sort!
    for file in files
      next if File.directory?(file) || File.symlink?(file)
      original = File.read(file)
      source = original.dup

      # source.gsub!(/(\w+)\ +/, '\1 ')
      begin
        source.gsub!(/[\ \t]+\n/, "\n")
      rescue Exception => e
        STDERR.puts "#{e.message} on #{file}"
      end
      # source.gsub!(/\n+\n$/, "\n")

      next unless source != original
      log.write " - #{file}\n"
      File.write(file, source)
      count += 1
    end
    log.close
    puts "#{count.to_s.rjust(3)} files updated"
  end
end
