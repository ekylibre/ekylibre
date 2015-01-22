module Ekylibre
  module Tele
    module Idele
      class Generator

        def initialize
          @resources_dir = File.dirname(__FILE__)+'/resources/'
          @transcoding_dir = File.dirname(__FILE__)+'/transcoding/'
          @in_dir = 'in/'
          @out_dir = 'out/'
        end

        def bos_taurus

          csv_url = @resources_dir+'codeTypeRacial.csv'
          transcoding_file_name = 'bos_taurus.yml'

          idele_race_code = {}
          out_matched_races = {}
          in_matched_races = {}
          nomen_varieties = {}

          if File.exist?(csv_url)

            CSV.foreach(csv_url, :headers => true, :col_sep => ',') do |row|

              #simple formatting
              key = row[1].squish.downcase.tr(' ', '_').tr('ç', 'c').tr("'", '').tr('(', '').tr(')', '').tr('é', 'e').tr('è', 'e')

              idele_race_code['bos_taurus_'+key] = {code: row[0],human_name: row[1], matched: 0}
            end


            Nomen::Varieties[:bos_taurus].children.each do |v|
              nomen_varieties[v.name] = {matched: 0}
            end

            ## OUT
            #
            nomen_varieties.each do |k,_|

              if idele_race_code.key?(k)
                out_matched_races[k] = idele_race_code[k][:code]
                nomen_varieties[k][:matched] = 1
              end

            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen bos taurus items: #{nomen_varieties.select{|k,v| v[:matched]==1}.size}/#{nomen_varieties.size}\n"

            results += "**#{nomen_varieties.select{|k,v| v[:matched]==0}.size} Missing Nomen Item Matching: \n"

            nomen_varieties.select{|k,v| v[:matched]==0}.each do |k, v|
              results += "#{k}\n"
            end

            #
            ##

            ## IN
            #

            #Reset matched indicators
            nomen_varieties.each_key { |k| nomen_varieties[k][:matched] = 0 }

            idele_race_code.each_key { |k| idele_race_code[k][:matched] = 0 }


            idele_race_code.each do |k,v|

              if nomen_varieties.key?(k)
                in_matched_races[v[:code]] = k
                idele_race_code[k][:matched] = 1
              end

            end

            results += "**Matched Idele csv race code: #{idele_race_code.select{|k,v| v[:matched]==1}.size}/#{idele_race_code.size}\n"

            results += "**#{idele_race_code.select{|k,v| v[:matched]==0}.size} Missing Idele race code Matching: \n"

            idele_race_code.select{|k,v| v[:matched]==0}.each do |k,v|
              results += "Code : #{v[:code]}, Human name: #{v[:human_name]}\n"
            end

            #
            ##

            ## RESULTS
            #
            File.open(@transcoding_dir+@out_dir+transcoding_file_name, 'w') {|f| f.write(out_matched_races.to_yaml) }

            File.open(@transcoding_dir+@in_dir+transcoding_file_name, 'w') {|f| f.write(in_matched_races.to_yaml) }

            print results

          else
            raise 'Idele codeTypeRacial.csv is missing for transcoding table generation'
          end

        end

        def sexes

          #type_name = 'typeSexe'
          xsd_url = @resources_dir+'IpBNotif_v1.xsd'
          transcoding_file_url = @transcoding_dir+'out/sexes.yml'

          idele_sexes = []
          idele_sexes_tracer = {}
          matched_sexes = {}
          nomen_sexes_tracer = {}

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="typeSexe"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|

              idele_sexes << v.to_s
              idele_sexes_tracer[v.to_s] = 0

              print "sexe: #{v.to_s}"
            end

          else
            raise 'Idele IPBNotif_v1.xsd is missing for sexe code import'
          end

          nomen_sexes = {}

          Nomen::Sexes.all.each do |s|
            key = s[0].to_s.upcase
            nomen_sexes[key] = s
          end


          nomen_sexes.each do |k,v|

            matched = 0


            if idele_sexes.include?(k)
              matched_sexes[v] = k

              idele_sexes_tracer[k] = 1

              matched = 1
            end

            nomen_sexes_tracer[k] = matched

          end

          print "### Transcoding Results ###\n"

          ###debug:
          #print idele_sexes.inspect
          #print nomen_sexes.inspect

          print "**Matched Nomen sexes items: #{nomen_sexes_tracer.select{|k,v| v==1}.size}/#{nomen_sexes.size}\n"

          print "**#{nomen_sexes_tracer.select{|k,v| v==0}.size} Missing Nomen Item Matching: \n"

          nomen_sexes_tracer.select{|k,v| v==0}.each_with_index do |v, i|
            print "#{i}: #{v[0]}\n"
          end

          print "**Matched Idele xsd sexes: #{idele_sexes_tracer.select{|k,v| v==1}.size}/#{idele_sexes.size}\n"

          print "**#{idele_sexes_tracer.select{|k,v| v==0}.size} Missing Idele sexes Matching: \n"

          idele_sexes_tracer.select{|k,v| v==0}.each_with_index do |v, i|
            print "#{i}: #{v[0]}\n"
          end

          File.open(transcoding_file_url, 'w') {|f| f.write(matched_sexes.to_yaml) }


        end

        def countries
          transcoding_file_url = @transcoding_dir+'countries.yml'

          nomen_countries = {}

          Nomen::Countries.all.each do |c|
            nomen_countries[c] = c.to_s.upcase
          end

          File.open(transcoding_file_url, 'w') {|f| f.write(nomen_countries.to_yaml) }

        end

        def mammalia_birth_conditions
          transcoding_file_url = @transcoding_dir+'mammalia_birth_conditions.yml'

          #can't be autogenerated
          # dumped from doc Conditions de naissance:
          #1: Sans aide
          #2: Avec aide facile
          #3: Avec recours à un tiers ou moyen mécanique
          #4: Césarienne
          #5: Embryotomie

          birth_conditions = {
            without_help: 1,
            few_help: 2,
            great_help: 3,
            caesarean: 4,
            newborn_cutting: 5
          }

          File.open(transcoding_file_url, 'w') {|f| f.write(birth_conditions.to_yaml) }

        end
      end
    end
  end
end