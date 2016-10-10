namespace :clean do
  task procedures: :environment do
    Procedo::Procedure.find_each do |procedure|
      messages = procedure.lint
      if messages.any?
        puts "#{procedure.name.to_s.red}:"
        messages.each do |msg|
          puts msg.yellow
        end
      end
    end
  end
end
