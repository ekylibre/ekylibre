# = Class based ActionView +field_error_proc+
# 
# Defines a new ActionView +field_error_proc+. The old +field_error_proc+ would
# wrap the form field into a +div+ element of the class +fieldWithErrors+.
# 
# This sometimes makes the design of these invalid form fields a bit difficult
# and may also produce invalid markup. To avoid all this the feature replaces
# this with an +field_error_proc+ that just adds the class +invalid+ to the
# form field and doesn't create a new element around it. If the form field
# element already has a class attribute the +invalid+ class will be appended to
# the class list.
# 
# Old field_error_proc:
# 
#   <div class="fieldWithErrors"><input type="text" class="txt" ... /></div>
# 
# New field_error_proc:
# 
#   <input type="text" class="txt invalid" ... />
# 
# This feature is based on the snippet of Duane Johnson which adds an style
# attribute to the form field element. He did the real work.
# http://wiki.rubyonrails.com/rails/pages/HowtoChangeValidationErrorDisplay
# 
# == Used sections of the language file
# 
# This feature doesn't use sections from the language file.

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  msg = instance.error_message
  error_class = 'invalid'
  
  if html_tag =~ /<(input|textarea|select)[^>]+class=/
    class_attribute = html_tag =~ /class=['"]/
    html_tag.insert(class_attribute + 7, "#{error_class} ")
  elsif html_tag =~ /<(input|textarea|select)/
    first_whitespace = html_tag =~ /\s/
    html_tag[first_whitespace] = " class=\"#{error_class}\" "
  end
  
  html_tag
end