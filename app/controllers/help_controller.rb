class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper

  def search
    code  = content_tag(:h2,  'Aide')
    code += content_tag(:div, params[:id])
    code  = content_tag(:div, code, :id=>:help, :flex=>1)
    render :text=>code
  end

  def none
    render :text=>''
  end

end
