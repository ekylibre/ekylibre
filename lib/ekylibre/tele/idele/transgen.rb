module Ekylibre
  module Tele
    module Idele
      class Transgen

        def Initialize

        end

        def bos_taurus

          ##### csv dump and yml generator
          csv_url = 'lib/ekylibre/tele/idele/assets/codeTypeRacial.csv'
          transcoding_file_url = 'lib/ekylibre/tele/idele/transcoding/erp_edi/bos_taurus.yml'

          race_code = {}
          race_code_tracer = {}
          matched_races = {}
          matched_races_tracer = {}

          if File.exist?(csv_url)

            CSV.foreach(csv_url, :headers => true, :col_sep => ',') do |row|

              #simple formatting
              key = row[1].squish.downcase.tr(' ', '_').tr('ç', 'c').tr("'", '').tr('(', '').tr(')', '').tr('é', 'e').tr('è', 'e')

              race_code['bos_taurus_'+key] = row[0]
            end

            race_code.each_key do |key|
              race_code_tracer[key] = 0
            end

            varieties = Nomen::Varieties[:bos_taurus].children


            varieties.each do |v|

              matched = 0

              if race_code.key?(v.name)
                matched_races[v.name] = race_code[v.name]

                race_code_tracer[v.name] = 1

                matched = 1
              end

              matched_races_tracer[v.name] = matched

            end



            print "### Transcoding Results ###\n"

            ###debug:
            #print matched_races.inspect
            #print matched_races_tracer.inspect
            #print race_code_tracer.inspect

            print "**Matched bos taurus items: #{matched_races_tracer.select{|k,v| v==1}.size}/#{varieties.size}\n"

            print "**#{matched_races_tracer.select{|k,v| v==0}.size} Missing Item Matching: \n"

            matched_races_tracer.select{|k,v| v==0}.each_with_index do |v, i|
              print "#{i}: #{v[0]}\n"
            end

            print "**Matched csv race code: #{race_code_tracer.select{|k,v| v==1}.size}/#{race_code.size}\n"

            print "**#{race_code_tracer.select{|k,v| v==0}.size} Missing race code Matching: \n"

            race_code_tracer.select{|k,v| v==0}.each_with_index do |v, i|
              print "#{i}: #{v[0]}\n"
            end

            File.open(transcoding_file_url, 'w') {|f| f.write(matched_races.to_yaml) }

          else
            raise 'Idele codeTypeRacial.csv is missing for french code race import'
          end

        end

        def sexes
          sexes = Nomen::Sexes.all

          print sexes.inspect

          #sex.each do |s|
          #  print Nomen::Sexes[s].name
          #end

          type_name = 'typeSexe'
          xsd_url = 'lib/ekylibre/tele/idele/assets/IpBNotif_v1.xsd'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="typeSexe"]/xsd:restriction/xsd:enumeration[attribute::value]')
            print values

          else
            raise 'Idele IPBNotif_v1.xsd is missing for sexe code import'
          end
        end
      end
    end
  end
end