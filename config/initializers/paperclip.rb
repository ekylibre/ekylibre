# Interpolate private in paperclip
Paperclip.interpolates :tenant do |_attachment, _style|
  Ekylibre::Tenant.private_directory.join('attachments')
end
Paperclip.options[:whiny] = false

require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
