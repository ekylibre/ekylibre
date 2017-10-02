# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
{
  jpg: 'image/jpeg',
  svg: 'image/svg+xml',
  zip: 'application/zip',
  # Portable Documents
  pdf: 'application/pdf',
  # Open Documents
  odt: 'application/vnd.oasis.opendocument.text',
  ods: 'application/vnd.oasis.opendocument.spreadsheet',
  odp: 'application/vnd.oasis.opendocument.presentation',
  odg: 'application/vnd.oasis.opendocument.graphics',
  # Open Templates
  ott: 'application/vnd.oasis.opendocument.text-template',
  ots: 'application/vnd.oasis.opendocument.spreadsheet-template',
  otp: 'application/vnd.oasis.opendocument.presentation-template',
  otg: 'application/vnd.oasis.opendocument.graphics-template',
  # Open XML Documents
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  pptx: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  # Open XML Templates
  dotx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
  xltx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
  potx: 'application/vnd.openxmlformats-officedocument.presentationml.template',
  # First-Run Archive
  fra: 'application/vnd.ekylibre.first-run.archive',
  # Geographic
  gml: 'application/gml+xml',
  kml: 'application/vnd.google-earth.kml+xml',
  kmz: 'application/vnd.google-earth.kmz'
}.each do |symbol, string|
  Mime::Type.register(string, symbol) unless Mime[symbol]
end
