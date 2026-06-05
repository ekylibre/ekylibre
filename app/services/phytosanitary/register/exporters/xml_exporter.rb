# frozen_string_literal: true

require 'nokogiri'

module Phytosanitary
  module Register
    module Exporters
      class XmlExporter < Base
        def call
          builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.PhytoRegister(xmlns: SCHEMA_URN, formatVersion: FORMAT_VERSION) do
              build_meta(xml)
              build_entries(xml)
            end
          end
          builder.to_xml
        end

        private

          def build_meta(xml)
            xml.Meta do
              meta_hash.each do |key, value|
                next if key == :schema || key == :format_version

                xml.send(camelize(key), value.to_s) unless value.nil?
              end
            end
          end

          def build_entries(xml)
            xml.Entries do
              @payload.entries.to_a.each do |entry|
                xml.Entry(
                  interventionId: entry.intervention_id,
                  interventionInputId: entry.intervention_input_id,
                  interventionTargetId: entry.intervention_target_id
                ) do
                  entry_hash(entry).each do |key, value|
                    next if %i[intervention_id intervention_input_id intervention_target_id].include?(key)
                    next if value.nil?

                    xml.send(camelize(key), value.to_s)
                  end
                end
              end
            end
          end

          def camelize(key)
            key.to_s.split('_').map(&:capitalize).join
          end
      end
    end
  end
end
