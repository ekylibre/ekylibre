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
    files.each do |file|
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
    log.write "\n"
    puts "#{count.to_s.rjust(3)} files updated"

    print ' - Quality: '
    files = `git status --porcelain`.split(/\n/).map do |l|
      x = l.strip.split(/\ /)
      file = x[1..-1].join(' ').strip.split(' -> ').last
      [x.first, file]
    end.select { |p| p.second =~ /\A(.+\.rb|.+\.rake|Rakefile)\z/ && p.first =~ /(A|M)/ }.map(&:second)
    log.write "Inspect:\n"
    files.each do |f|
      log.write " - #{f}\n"
    end
    log.write "\n"
    log.write `rubocop --auto-correct --no-color #{files.join(' ')}`
    log.close
    puts `tail -n 1 log/clean-code.log`
  end
end
