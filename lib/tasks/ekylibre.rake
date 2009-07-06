require 'csv'

namespace :rights do

  desc "Update and sort rights list"
  task :sort => :environment do
    # Chargement des actions des controllers
    ref = {}
    Dir.glob("#{RAILS_ROOT}/app/controllers/*_controller.rb") do |x|
      controller_name = x.split("/")[-1].split("_controller")[0]
      actions = []
      file = File.open(x, "r")
      file.each_line do |line|
        actions << line.split(/def\s/)[1].gsub(/\s/,'') if line.match(/^\s*def\s+\w+\s*$/)
        actions << line.gsub(/\s/,'').gsub("(:","_").split(/(\,|\))/)[0] if line.match(/^\s*dyta[\s\(]+\:\w+/)
      end
      ref[controller_name] = actions
    end

    # Lecture du fichier existant
    file = File.open("#{RAILS_ROOT}/config/rights.txt", "r") 
    rights = []
    file.each_line do |line|
      right = line.strip.split(":").collect{|x| x.strip.lower}
      right[2] = 'administrate_'+right[0].to_s if right.size==2
      rights << right if right.size==3
    end
    file.close

    # Mise en commentaire des actions supprimées
    deleted = 0
    for right in rights
      unless right[0].match(/^\#/)
        unless ref[right[0]].include?(right[1])
          right[0] = '# '+right[0] 
          deleted += 1
        end
      end
    end

    # Ajout des nouvelles actions
    created = 0
    for controller_name, actions in ref
      for a in actions
        unless rights.select{|r| r[0].gsub(/(\#|\s)/,'')==controller_name and r[1]==a}.size>0
          rights << [controller_name, a, '<new>'] 
          created += 1
        end
      end
    end

    # Droits non affectés
    to_update = 0
    for right in rights
      to_update += 1 if right[2].match(/\</)
    end

    # Tri
    rights.sort!{|a, b| a[0]+':'+a[2]+':'+a[1]<=>b[0]+':'+b[2]+':'+b[1]}

    # Enregistrement du nouveau fichier
    file = File.open("#{RAILS_ROOT}/config/rights.txt", "wb") 
    file.write rights.collect{|x| x.join(":")}.join("\n")
    file.close

    puts "#{deleted} deleted actions, #{created} created actions, #{to_update} actions to update"
  end
end
