require 'rfpdf'

ActionView::Template::register_template_handler 'rfpdf', RFPDF::View
ActionView::Template::register_template_handler 'tcpdf', RFPDF::View
