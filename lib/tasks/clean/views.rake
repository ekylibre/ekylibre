namespace :clean do
  task views: :environment do
    log = File.open(Rails.root.join('log', 'clean-code.log'), 'wb')
    log.write "Views:\n"

    controllers = Clean::Support.controllers_in_file.map(&:controller_path)

    mailers = Dir.chdir(Rails.root.join('app', 'mailers')) do
      Dir.glob('**/*.rb').map do |f|
        f.gsub(/.rb$/, '')
      end
    end

    views = Dir.chdir(Rails.root.join('app', 'views')) do
      Dir.glob('**/*').delete_if do |f|
        File.basename(f) =~ /^_/ || File.directory?(f)
      end.map do |x|
        File.dirname(x)
      end.uniq
    end

    suspects = (views - controllers - mailers).delete_if do |f|
      f =~ /\bshared\b/
    end.delete_if do |f|
      f =~ /^(devise|layouts)/
    end

    log.write "Please remove:\n" + suspects.join("\n") if suspects.any?
    puts " - Views: #{suspects.count.to_s.rjust(3)} useless folder detected"
    log.close
  end
end
