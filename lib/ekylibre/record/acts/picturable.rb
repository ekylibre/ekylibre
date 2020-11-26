module Ekylibre
  module Record
    module Acts
      module Picturable
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_picture(options = {})
            default_options = {
              url: '/backend/:class/:id/picture/:style',
              path: ':tenant/:class/:attachment/:id_partition/:style.:extension',
              styles: {
                thumb: ['64x64>', :jpg],
                identity: ['180x180#', :jpg],
                contact: ['720x720#', :jpg]
              },
              convert_options: {
                thumb:    '-background white -gravity center -extent 64x64',
                identity: '-background white -gravity center -extent 180x180',
                contact: '-background white -gravity center -extent 720x720'
              }
            }
            has_attached_file :picture, default_options.deep_merge(options)
          end
        end
      end
    end
  end
end
