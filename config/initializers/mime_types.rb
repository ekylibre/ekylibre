# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register("image/jpeg", :jpg) unless defined? Mime::JPG
Mime::Type.register("image/svg+xml", :svg) unless defined? Mime::SVG
Mime::Type.register("application/zip", :zip) unless defined? Mime::ZIP
# Portable Documents
Mime::Type.register("application/pdf", :pdf) unless defined? Mime::PDF
# Open Documents
Mime::Type.register("application/vnd.oasis.opendocument.text", :odt) unless defined? Mime::ODT
Mime::Type.register("application/vnd.oasis.opendocument.spreadsheet", :ods) unless defined? Mime::ODS
Mime::Type.register("application/vnd.oasis.opendocument.presentation", :odp) unless defined? Mime::ODP
Mime::Type.register("application/vnd.oasis.opendocument.graphics", :odg) unless defined? Mime::ODG
# Open Templates
Mime::Type.register("application/vnd.oasis.opendocument.text-template", :ott) unless defined? Mime::OTT
Mime::Type.register("application/vnd.oasis.opendocument.spreadsheet-template", :ots) unless defined? Mime::OTS
Mime::Type.register("application/vnd.oasis.opendocument.presentation-template", :otp) unless defined? Mime::OTP
Mime::Type.register("application/vnd.oasis.opendocument.graphics-template", :otg) unless defined? Mime::OTG
# Open XML Documents
Mime::Type.register("application/vnd.openxmlformats-officedocument.wordprocessingml.document", :docx) unless defined? Mime::DOCX
Mime::Type.register("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :xlsx) unless defined? Mime::XLSX
Mime::Type.register("application/vnd.openxmlformats-officedocument.presentationml.presentation", :pptx) unless defined? Mime::PPTX
# Open XML Templates
Mime::Type.register("application/vnd.openxmlformats-officedocument.wordprocessingml.template", :dotx) unless defined? Mime::DOTX
Mime::Type.register("application/vnd.openxmlformats-officedocument.spreadsheetml.template", :xltx) unless defined? Mime::XLTX
Mime::Type.register("application/vnd.openxmlformats-officedocument.presentationml.template", :potx) unless defined? Mime::POTX
# First-Run Archive
Mime::Type.register("application/vnd.ekylibre.first-run.archive", :fra) unless defined? Mime::FRA
