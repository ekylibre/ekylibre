namespace :clean do

  task :views => :environment do
    log = File.open(Rails.root.join("log", "clean-code.log"), "wb")
    log.write "Views:\n"

    controllers = Clean::Support.controllers_in_file.map do |c|
      c.controller_path
    end

    mailers = Dir.chdir(Rails.root.join("app", "mailers")) do
      Dir.glob("**/*.rb").map do |f|
        f.gsub(/.rb$/, '')
      end
    end

    views = Dir.chdir(Rails.root.join("app", "views")) do
      Dir.glob("**/*").delete_if do |f|
        File.basename(f) =~ /^_/ or File.directory?(f)
      end.map do |x|
        File.dirname(x)
      end.uniq
    end

    suspects = (views - controllers - mailers).delete_if do |f|
      f =~  /\bshared\b/
    end.delete_if do |f|
      f =~  /^(devise|layouts)/
    end

    if suspects.any?
      log.write "Please remove:\n" + suspects.join("\n")
    end
    puts " - Views: #{suspects.count.to_s.rjust(3)} useless folder detected"
    log.close
  end

end
