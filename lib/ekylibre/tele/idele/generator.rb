module Ekylibre
  module Tele
    module Idele
      class Generator
        def initialize
          @resources_dir = File.dirname(__FILE__) + '/resources/'
          @transcoding_dir = File.dirname(__FILE__) + '/transcoding/'
          @in_dir = 'in/'
          @out_dir = 'out/'
        end

        def bos_taurus
          csv_url = @resources_dir + 'codeTypeRacial.csv'
          transcoding_filename = 'bos_taurus.yml'
          transcoding_exception_filename = 'bos_taurus.exception.yml'

          idele_race_code = {}
          out_matched_races = {}
          in_matched_races = {}
          out_exception_races = {}
          in_exception_races = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_varieties = {}

          if File.exist?(csv_url)

            CSV.foreach(csv_url, headers: true, col_sep: ',') do |row|
              # simple formatting
              key = row[1].squish.downcase.tr(' ', '_').tr('ç', 'c').tr("'", '').tr('(', '').tr(')', '').tr('é', 'e').tr('è', 'e')

              idele_race_code['bos_taurus_' + key] = { code: row[0], human_name: row[1], matched: 0 }
            end

            Nomen::Variety[:bos_taurus].children.each do |v|
              nomen_varieties[v.name] = { matched: 0 }
            end

            ## OUT
            #

            nomen_varieties.each do |k, _|
              if idele_race_code.key?(k)
                out_matched_races[k] = idele_race_code[k][:code]
                nomen_varieties[k][:matched] = 1
              end
            end

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_races.reverse_merge!(out_existing_exception)

              out_existing_exception.each do |k, _|
                nomen_varieties[k][:matched] = 1 if nomen_varieties.key?(k)
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen bos taurus items: #{nomen_varieties.count { |_, v| v[:matched] == 1 }}/#{nomen_varieties.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_varieties.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_varieties.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              out_exception_races[k] = nil
            end

            #
            ##

            ## IN
            #

            # Reset matched indicators
            nomen_varieties.each_key { |k| nomen_varieties[k][:matched] = 0 }

            idele_race_code.each_key { |k| idele_race_code[k][:matched] = 0 }

            idele_race_code.each do |k, v|
              if nomen_varieties.key?(k)
                in_matched_races[v[:code]] = k
                idele_race_code[k][:matched] = 1
              end
            end

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_races.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_race_code.select { |_, v| v[:code] == c.to_s }.each do |k, _|
                  idele_race_code[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele csv race code: #{idele_race_code.count { |_, v| v[:matched] == 1 }}/#{idele_race_code.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_race_code.count { |_, v| v[:matched] == 0 }} Missing Idele race code Matching: \n"

            idele_race_code.select { |_, v| v[:matched] == 0 }.each do |_, v|
              results += "Code : #{v[:code]}, Human name: #{v[:human_name]}\n"
              in_exception_races[v[:code]] = nil
            end

            #
            ##

            ## RESULTS
            #
            File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_races.to_yaml) }

            File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_races.to_yaml) }

            if out_exception_races.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_races.to_yaml) }
            end

            if in_exception_races.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_races.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele codeTypeRacial.csv is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def sexes
          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'sexes.yml'
          transcoding_exception_filename = 'sexes.exception.yml'

          out_matched_sexes = {}
          in_matched_sexes = {}
          out_exception_sexes = {}
          in_exception_sexes = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_sexes = {}
          idele_sexes = {}

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="typeSexe"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_sexes[v.to_s] = { matched: 0 }
            end

            print idele_sexes.inspect

            Nomen::Sex.all.each do |s|
              key = s[0].to_s.upcase
              nomen_sexes[key] = { matched: 0, nomenclature: s }
            end

            print nomen_sexes.inspect

            ## OUT
            #

            nomen_sexes.each do |k, v|
              if idele_sexes.key?(k)
                out_matched_sexes[v[:nomenclature]] = k
                nomen_sexes[k][:matched] = 1
              end
            end

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_sexes.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_sexes.select { |_, v| v[:nomenclature] == e }.each do |k, _|
                  nomen_sexes[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen sexes items: #{nomen_sexes.count { |_, v| v[:matched] == 1 }}/#{nomen_sexes.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_sexes.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_sexes.select { |_, v| v[:matched] == 0 }.each do |_, v|
              results += "Nomenclature: #{v[:nomenclature]}\n"
              out_exception_sexes[v[:nomenclature]] = nil
            end

            #
            ##

            ## IN
            #

            # Reset matched indicators
            nomen_sexes.each_key { |k| nomen_sexes[k][:matched] = 0 }

            idele_sexes.each_key { |k| idele_sexes[k][:matched] = 0 }
            #

            idele_sexes.each do |k, _v|
              if nomen_sexes.key?(k)
                in_matched_sexes[k] = nomen_sexes[k][:nomenclature]
                idele_sexes[k][:matched] = 1
              end
            end

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_sexes.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_sexes.select { |_, v| v[:code] == c.to_s }.each do |k, _|
                  idele_sexes[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele sexes: #{idele_sexes.count { |_, v| v[:matched] == 1 }}/#{idele_sexes.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_sexes.count { |_, v| v[:matched] == 0 }} Missing Idele sexes Matching: \n"

            idele_sexes.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_sexes[k] = nil
            end

            #
            ##

            ## RESULTS
            #
            File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_sexes.to_yaml) }

            File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_sexes.to_yaml) }

            if out_exception_sexes.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_sexes.to_yaml) }
            end

            if in_exception_sexes.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_sexes.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IPBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def countries
          transcoding_filename = 'countries.yml'

          nomen_countries = {}
          idele_countries = {}

          Nomen::Country.all.each do |c|
            nomen_countries[c] = c.to_s.upcase
            idele_countries[c.to_s.upcase] = c
          end

          ## RESULTS
          #
          File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(nomen_countries.to_yaml) }

          File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(idele_countries.to_yaml) }
        end

        def mammalia_birth_conditions
          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'mammalia_birth_conditions.yml'
          transcoding_exception_filename = 'mammalia_birth_conditions.exception.yml'

          out_matched_mammalia_birth_conditions = {}
          in_matched_mammalia_birth_conditions = {}
          out_exception_mammalia_birth_conditions = {}
          in_exception_mammalia_birth_conditions = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_mammalia_birth_conditions = {}
          idele_mammalia_birth_conditions = {}

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="typeConditionNaissance"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_mammalia_birth_conditions[v.to_s] = { matched: 0 }
            end

            print idele_mammalia_birth_conditions.inspect

            Nomen::MammaliaBirthCondition.all.each do |s|
              nomen_mammalia_birth_conditions[s] = { matched: 0 }
            end

            print nomen_mammalia_birth_conditions.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_mammalia_birth_conditions.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_mammalia_birth_conditions.select { |k, _| k == e }.each do |k, _|
                  nomen_mammalia_birth_conditions[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Mammalia birth conditions items: #{nomen_mammalia_birth_conditions.count { |_, v| v[:matched] == 1 }}/#{nomen_mammalia_birth_conditions.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_mammalia_birth_conditions.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_mammalia_birth_conditions.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_mammalia_birth_conditions[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_mammalia_birth_conditions.each_key { |k| nomen_mammalia_birth_conditions[k][:matched] = 0 }

            idele_mammalia_birth_conditions.each_key { |k| idele_mammalia_birth_conditions[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_mammalia_birth_conditions.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_mammalia_birth_conditions.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_mammalia_birth_conditions[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele mammalia_birth_conditions: #{idele_mammalia_birth_conditions.count { |_, v| v[:matched] == 1 }}/#{idele_mammalia_birth_conditions.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_mammalia_birth_conditions.count { |_, v| v[:matched] == 0 }} Missing Idele mammalia_birth_conditions Matching: \n"

            idele_mammalia_birth_conditions.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_mammalia_birth_conditions[k] = nil
            end

            #
            ##

            # can't be autogenerated
            # dumped from doc Conditions de naissance:
            # 1: Sans aide
            # 2: Avec aide facile
            # 3: Avec recours à un tiers ou moyen mécanique
            # 4: Césarienne
            # 5: Embryotomie

            ## RESULTS
            #

            if out_matched_mammalia_birth_conditions.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_mammalia_birth_conditions.to_yaml) }
            end

            if in_matched_mammalia_birth_conditions.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_mammalia_birth_conditions.to_yaml) }
            end

            if out_exception_mammalia_birth_conditions.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_mammalia_birth_conditions.to_yaml) }
            end

            if in_exception_mammalia_birth_conditions.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_mammalia_birth_conditions.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IPBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def entry_reason
          # TODO: entry reason erp nomenclature

          # dumped from doc
          # A: Achat
          # P: Prêt / Pension

          out_matched_entry_reason = {}
          in_matched_entry_reason = {}
          out_exception_entry_reason = {}
          in_exception_entry_reason = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_entry_reason = {}
          idele_entry_reason = {}

          xsd_url = @resources_dir + 'CauseEntree.XSD'
          transcoding_filename = 'entry_reason.yml'
          transcoding_exception_filename = 'entry_reason.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="CauseEntreeType"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_entry_reason[v.to_s] = { matched: 0 }
            end

            print idele_entry_reason.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_entry_reason[s] = {matched: 0}
            # end

            # print nomen_entry_reason.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_entry_reason.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_entry_reason.select { |k, _| k == e }.each do |k, _|
                  nomen_entry_reason[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Entry Reason items: #{nomen_entry_reason.count { |_, v| v[:matched] == 1 }}/#{nomen_entry_reason.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_entry_reason.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_entry_reason.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_entry_reason[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_entry_reason.each_key { |k| nomen_entry_reason[k][:matched] = 0 }

            idele_entry_reason.each_key { |k| idele_entry_reason[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_entry_reason.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_entry_reason.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_entry_reason[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele entry_reason: #{idele_entry_reason.count { |_, v| v[:matched] == 1 }}/#{idele_entry_reason.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_entry_reason.count { |_, v| v[:matched] == 0 }} Missing Idele entry_reason Matching: \n"

            idele_entry_reason.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_entry_reason[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_entry_reason.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_entry_reason.to_yaml) }
            end

            if in_matched_entry_reason.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_entry_reason.to_yaml) }
            end

            if out_exception_entry_reason.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_entry_reason.to_yaml) }
            end

            if in_exception_entry_reason.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_entry_reason.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele CauseEntree.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def prod_code
          # TODO: code atelier défini page 18
        end

        def cattle_categ_code
          # TODO: Code categorie bovin défini page 19
        end

        def exit_reason
          # TODO: exit reason erp nomenclature

          # dumped from doc
          # B: boucherie
          # C: auto-consommation
          # E: vente en élevage
          # H: Prêt/Pension
          # M: mort

          out_matched_exit_reason = {}
          in_matched_exit_reason = {}
          out_exception_exit_reason = {}
          in_exception_exit_reason = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_exit_reason = {}
          idele_exit_reason = {}

          xsd_url = @resources_dir + 'CauseSortie.XSD'
          transcoding_filename = 'exit_reason.yml'
          transcoding_exception_filename = 'exit_reason.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="CauseSortieType"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_exit_reason[v.to_s] = { matched: 0 }
            end

            print idele_exit_reason.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_exit_reason[s] = {matched: 0}
            # end

            # print nomen_exit_reason.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_exit_reason.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_exit_reason.select { |k, _| k == e }.each do |k, _|
                  nomen_exit_reason[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Exit Reason items: #{nomen_exit_reason.count { |_, v| v[:matched] == 1 }}/#{nomen_exit_reason.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_exit_reason.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_exit_reason.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_exit_reason[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_exit_reason.each_key { |k| nomen_exit_reason[k][:matched] = 0 }

            idele_exit_reason.each_key { |k| idele_exit_reason[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_exit_reason.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_exit_reason.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_exit_reason[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele exit_reason: #{idele_exit_reason.count { |_, v| v[:matched] == 1 }}/#{idele_exit_reason.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_exit_reason.count { |_, v| v[:matched] == 0 }} Missing Idele exit_reason Matching: \n"

            idele_exit_reason.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_exit_reason[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_exit_reason.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_exit_reason.to_yaml) }
            end

            if in_matched_exit_reason.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_exit_reason.to_yaml) }
            end

            if out_exception_exit_reason.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_exit_reason.to_yaml) }
            end

            if in_exception_exit_reason.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_exit_reason.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele CauseSortie.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def temoin_completude
          # TODO: temoin completude erp nomenclature

          # dumped from doc
          # 0 : Date complète
          # 1 : Seul le mois et l’année sont à prendre en compte
          # 2 : Seule l’année est à prendre en compte

          out_matched_temoin_completude = {}
          in_matched_temoin_completude = {}
          out_exception_temoin_completude = {}
          in_exception_temoin_completude = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_temoin_completude = {}
          idele_temoin_completude = {}

          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'temoin_completude.yml'
          transcoding_exception_filename = 'temoin_completude.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="typeTemoinCompletude"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_temoin_completude[v.to_s] = { matched: 0 }
            end

            print idele_temoin_completude.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_temoin_completude[s] = {matched: 0}
            # end

            # print nomen_temoin_completude.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_temoin_completude.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_temoin_completude.select { |k, _| k == e }.each do |k, _|
                  nomen_temoin_completude[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Temoin completude items: #{nomen_temoin_completude.count { |_, v| v[:matched] == 1 }}/#{nomen_temoin_completude.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_temoin_completude.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_temoin_completude.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_temoin_completude[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_temoin_completude.each_key { |k| nomen_temoin_completude[k][:matched] = 0 }

            idele_temoin_completude.each_key { |k| idele_temoin_completude[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_temoin_completude.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_temoin_completude.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_temoin_completude[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele temoin_completude: #{idele_temoin_completude.count { |_, v| v[:matched] == 1 }}/#{idele_temoin_completude.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_temoin_completude.count { |_, v| v[:matched] == 0 }} Missing Idele temoin_completude Matching: \n"

            idele_temoin_completude.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_temoin_completude[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_temoin_completude.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_temoin_completude.to_yaml) }
            end

            if in_matched_temoin_completude.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_temoin_completude.to_yaml) }
            end

            if out_exception_temoin_completude.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_temoin_completude.to_yaml) }
            end

            if in_exception_temoin_completude.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_temoin_completude.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IpBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def temoin_fin_de_vie
          # TODO: temoin fin_de_vie erp nomenclature

          # dumped from doc
          # M: Mort
          # A: Abattage
          # E: Equarrissage
          # C: Date calculée

          out_matched_temoin_fin_de_vie = {}
          in_matched_temoin_fin_de_vie = {}
          out_exception_temoin_fin_de_vie = {}
          in_exception_temoin_fin_de_vie = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_temoin_fin_de_vie = {}
          idele_temoin_fin_de_vie = {}

          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'temoin_fin_de_vie.yml'
          transcoding_exception_filename = 'temoin_fin_de_vie.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:element[attribute::name="TemoinFinDeVie"]/xsd:simpleType/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_temoin_fin_de_vie[v.to_s] = { matched: 0 }
            end

            print idele_temoin_fin_de_vie.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_temoin_fin_de_vie[s] = {matched: 0}
            # end

            # print nomen_temoin_fin_de_vie.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_temoin_fin_de_vie.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_temoin_fin_de_vie.select { |k, _| k == e }.each do |k, _|
                  nomen_temoin_fin_de_vie[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Temoin fin_de_vie items: #{nomen_temoin_fin_de_vie.count { |_, v| v[:matched] == 1 }}/#{nomen_temoin_fin_de_vie.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_temoin_fin_de_vie.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_temoin_fin_de_vie.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_temoin_fin_de_vie[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_temoin_fin_de_vie.each_key { |k| nomen_temoin_fin_de_vie[k][:matched] = 0 }

            idele_temoin_fin_de_vie.each_key { |k| idele_temoin_fin_de_vie[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_temoin_fin_de_vie.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_temoin_fin_de_vie.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_temoin_fin_de_vie[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele temoin_fin_de_vie: #{idele_temoin_fin_de_vie.count { |_, v| v[:matched] == 1 }}/#{idele_temoin_fin_de_vie.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_temoin_fin_de_vie.count { |_, v| v[:matched] == 0 }} Missing Idele temoin_fin_de_vie Matching: \n"

            idele_temoin_fin_de_vie.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_temoin_fin_de_vie[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_temoin_fin_de_vie.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_temoin_fin_de_vie.to_yaml) }
            end

            if in_matched_temoin_fin_de_vie.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_temoin_fin_de_vie.to_yaml) }
            end

            if out_exception_temoin_fin_de_vie.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_temoin_fin_de_vie.to_yaml) }
            end

            if in_exception_temoin_fin_de_vie.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_temoin_fin_de_vie.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IpBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def cause_remplacement
          # TODO: cause remplacement erp nomenclature

          # dumped from doc
          # C: Repère cassé
          # E: Electronisation
          # I: Repère illisible
          # L: Repère électronique perdu
          # P: Repère perdu
          # X: Anomalie de commande
          # Y: Anomalie de pose
          # Z: Anomalie de fabrication

          out_matched_cause_remplacement = {}
          in_matched_cause_remplacement = {}
          out_exception_cause_remplacement = {}
          in_exception_cause_remplacement = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_cause_remplacement = {}
          idele_cause_remplacement = {}

          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'cause_remplacement.yml'
          transcoding_exception_filename = 'cause_remplacement.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//xsd:simpleType[attribute::name="typeCauseRemplacement"]/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_cause_remplacement[v.to_s] = { matched: 0 }
            end

            print idele_cause_remplacement.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_cause_remplacement[s] = {matched: 0}
            # end

            # print nomen_cause_remplacement.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_cause_remplacement.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_cause_remplacement.select { |k, _| k == e }.each do |k, _|
                  nomen_cause_remplacement[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen cause remplacement items: #{nomen_cause_remplacement.count { |_, v| v[:matched] == 1 }}/#{nomen_cause_remplacement.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_cause_remplacement.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_cause_remplacement.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_cause_remplacement[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_cause_remplacement.each_key { |k| nomen_cause_remplacement[k][:matched] = 0 }

            idele_cause_remplacement.each_key { |k| idele_cause_remplacement[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_cause_remplacement.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_cause_remplacement.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_cause_remplacement[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele cause_remplacement: #{idele_cause_remplacement.count { |_, v| v[:matched] == 1 }}/#{idele_cause_remplacement.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_cause_remplacement.count { |_, v| v[:matched] == 0 }} Missing Idele cause_remplacement Matching: \n"

            idele_cause_remplacement.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_cause_remplacement[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_cause_remplacement.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_cause_remplacement.to_yaml) }
            end

            if in_matched_cause_remplacement.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_cause_remplacement.to_yaml) }
            end

            if out_exception_cause_remplacement.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_cause_remplacement.to_yaml) }
            end

            if in_exception_cause_remplacement.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_cause_remplacement.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IpBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def mode_insemination
          # TODO: mode insemination erp nomenclature

          # dumped from doc
          # F : Fraîche
          # C : Congelé

          out_matched_mode_insemination = {}
          in_matched_mode_insemination = {}
          out_exception_mode_insemination = {}
          in_exception_mode_insemination = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_mode_insemination = {}
          idele_mode_insemination = {}

          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'mode_insemination.yml'
          transcoding_exception_filename = 'mode_insemination.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//element[attribute::name="ModeInsemination"]/xsd:simpleType/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_mode_insemination[v.to_s] = { matched: 0 }
            end

            print idele_mode_insemination.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_mode_insemination[s] = {matched: 0}
            # end

            # print nomen_mode_insemination.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_mode_insemination.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_mode_insemination.select { |k, _| k == e }.each do |k, _|
                  nomen_mode_insemination[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen mode insemination items: #{nomen_mode_insemination.count { |_, v| v[:matched] == 1 }}/#{nomen_mode_insemination.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_mode_insemination.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_mode_insemination.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_mode_insemination[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_mode_insemination.each_key { |k| nomen_mode_insemination[k][:matched] = 0 }

            idele_mode_insemination.each_key { |k| idele_mode_insemination[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_mode_insemination.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_mode_insemination.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_mode_insemination[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele mode_insemination: #{idele_mode_insemination.count { |_, v| v[:matched] == 1 }}/#{idele_mode_insemination.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_mode_insemination.count { |_, v| v[:matched] == 0 }} Missing Idele mode_insemination Matching: \n"

            idele_mode_insemination.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_mode_insemination[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_mode_insemination.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_mode_insemination.to_yaml) }
            end

            if in_matched_mode_insemination.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_mode_insemination.to_yaml) }
            end

            if out_exception_mode_insemination.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_mode_insemination.to_yaml) }
            end

            if in_exception_mode_insemination.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_mode_insemination.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IpBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def paillette_fractionnee
          # TODO: paillette fractionnee erp nomenclature

          # dumped from doc
          # 1 : Paillette non fractionnée
          # 2 : Paillette fractionnée
          # B : double dose (bis)
          # D : Demi paillette
          # M : Morceau de paillette
          # P : Paillette entière
          # Q : Quart de paillette
          # T : Tiers de paillette

          out_matched_paillette_fractionnee = {}
          in_matched_paillette_fractionnee = {}
          out_exception_paillette_fractionnee = {}
          in_exception_paillette_fractionnee = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_paillette_fractionnee = {}
          idele_paillette_fractionnee = {}

          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'paillette_fractionnee.yml'
          transcoding_exception_filename = 'paillette_fractionnee.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//element[attribute::name="PailletteFractionnee"]/xsd:simpleType/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_paillette_fractionnee[v.to_s] = { matched: 0 }
            end

            print idele_paillette_fractionnee.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_paillette_fractionnee[s] = {matched: 0}
            # end

            # print nomen_paillette_fractionnee.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_paillette_fractionnee.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_paillette_fractionnee.select { |k, _| k == e }.each do |k, _|
                  nomen_paillette_fractionnee[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Paillette fractionnee items: #{nomen_paillette_fractionnee.count { |_, v| v[:matched] == 1 }}/#{nomen_paillette_fractionnee.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_paillette_fractionnee.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_paillette_fractionnee.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_paillette_fractionnee[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_paillette_fractionnee.each_key { |k| nomen_paillette_fractionnee[k][:matched] = 0 }

            idele_paillette_fractionnee.each_key { |k| idele_paillette_fractionnee[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_paillette_fractionnee.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_paillette_fractionnee.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_paillette_fractionnee[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele paillette_fractionnee: #{idele_paillette_fractionnee.count { |_, v| v[:matched] == 1 }}/#{idele_paillette_fractionnee.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_paillette_fractionnee.count { |_, v| v[:matched] == 0 }} Missing Idele paillette_fractionnee Matching: \n"

            idele_paillette_fractionnee.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_paillette_fractionnee[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_paillette_fractionnee.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_paillette_fractionnee.to_yaml) }
            end

            if in_matched_paillette_fractionnee.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_paillette_fractionnee.to_yaml) }
            end

            if out_exception_paillette_fractionnee.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_paillette_fractionnee.to_yaml) }
            end

            if in_exception_paillette_fractionnee.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_paillette_fractionnee.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IpBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end

        def semence_sexee
          # TODO: semence sexee erp nomenclature

          # dumped from doc
          # 0 : non sexée
          # 1 : sexée mâle
          # 2 : sexée femelle

          out_matched_semence_sexee = {}
          in_matched_semence_sexee = {}
          out_exception_semence_sexee = {}
          in_exception_semence_sexee = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_semence_sexee = {}
          idele_semence_sexee = {}

          xsd_url = @resources_dir + 'IpBNotif_v1.xsd'
          transcoding_filename = 'semence_sexee.yml'
          transcoding_exception_filename = 'semence_sexee.exception.yml'

          if File.exist?(xsd_url)

            doc = Nokogiri::XML(File.open(xsd_url))

            values = doc.xpath('//element[attribute::name="SemenceSexee"]/xsd:simpleType/xsd:restriction/xsd:enumeration[attribute::value]')
            values = values.xpath('attribute::value')

            values.each do |v|
              idele_semence_sexee[v.to_s] = { matched: 0 }
            end

            print idele_semence_sexee.inspect

            # TODO
            # Nomen::MammaliaBirthCondition.all.each do |s|

            #  nomen_semence_sexee[s] = {matched: 0}
            # end

            # print nomen_semence_sexee.inspect

            ## OUT
            #

            if File.exist?(@transcoding_dir + @out_dir + transcoding_exception_filename)
              out_existing_exception = YAML.load_file(@transcoding_dir + @out_dir + transcoding_exception_filename)

              out_matched_semence_sexee.reverse_merge!(out_existing_exception)

              print out_existing_exception.inspect

              out_existing_exception.each do |e, _|
                nomen_semence_sexee.select { |k, _| k == e }.each do |k, _|
                  nomen_semence_sexee[k][:matched] = 1
                end
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen Semence Sexee items: #{nomen_semence_sexee.count { |_, v| v[:matched] == 1 }}/#{nomen_semence_sexee.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_semence_sexee.count { |_, v| v[:matched] == 0 }} Missing Nomen Item Matching: \n"

            nomen_semence_sexee.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "Nomenclature: #{k}\n"
              out_exception_semence_sexee[k] = nil
            end

            #
            ##
            ## IN
            #

            # Reset matched indicators
            nomen_semence_sexee.each_key { |k| nomen_semence_sexee[k][:matched] = 0 }

            idele_semence_sexee.each_key { |k| idele_semence_sexee[k][:matched] = 0 }
            #

            if File.exist?(@transcoding_dir + @in_dir + transcoding_exception_filename)
              in_existing_exception = YAML.load_file(@transcoding_dir + @in_dir + transcoding_exception_filename)

              in_matched_semence_sexee.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_semence_sexee.select { |k, _| k == c.to_s }.each do |k, _|
                  idele_semence_sexee[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele semence_sexee: #{idele_semence_sexee.count { |_, v| v[:matched] == 1 }}/#{idele_semence_sexee.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_semence_sexee.count { |_, v| v[:matched] == 0 }} Missing Idele semence_sexee Matching: \n"

            idele_semence_sexee.select { |_, v| v[:matched] == 0 }.each do |k, _|
              results += "#{k}\n"
              in_exception_semence_sexee[k] = nil
            end

            #
            ##

            ## RESULTS
            #

            if out_matched_semence_sexee.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_filename, 'w') { |f| f.write(out_matched_semence_sexee.to_yaml) }
            end

            if in_matched_semence_sexee.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_filename, 'w') { |f| f.write(in_matched_semence_sexee.to_yaml) }
            end

            if out_exception_semence_sexee.size > 0
              File.open(@transcoding_dir + @out_dir + transcoding_exception_filename, 'a+') { |f| f.write(out_exception_semence_sexee.to_yaml) }
            end

            if in_exception_semence_sexee.size > 0
              File.open(@transcoding_dir + @in_dir + transcoding_exception_filename, 'a+') { |f| f.write(in_exception_semence_sexee.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele IpBNotif_v1.xsd is missing for transcoding table #{transcoding_filename} generation"
          end
        end
      end
    end
  end
end
