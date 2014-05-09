# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.x  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::HelpsController < BackendController

  helper_method :authorized?

  # Save the shown/hidden state of the help
  def toggle
    collapsed = !params[:collapsed].to_i.zero?
    p = current_user.preference("interface.helps.collapsed", false, :boolean)
    p.set!(collapsed)
    head :ok
  end

  def show
    file = search_article(params[:id])
    if request.xhr?
      render :partial => 'search', :object => file
      return
    else
      @help = file
    end
    t3e :title => Ekylibre.helps[file][:title]
  end



  def index
    per_page = 10
    if request.xhr?
      render :inline => "<%=article(params[:article], :url => {controller: :helps, action: :index, id: '\1'}, :update => :helpage)-%>"
    else
      @search = {}
      page = params[:page].to_i
      page = 1 if page.zero?
      key = params[:q] || session[:help_key]
      session[:help_key] = key
      key_words = key.to_s.lower.split(/[\s\,]+/).select{|x| x.length > 1}

      results = Ekylibre.helps[I18n.locale].values

      if key_words.size > 0
        @search[:words] = key_words
        reg = /(#{key_words.join("|")})/i
        results.delete_if do |details|
          file = details["file"]
          File.open(file, "rb:UTF-8") do |f|
            data = f.read
            details.update(:count => data.scan(reg).size)
          end
          details[:count].zero?
        end

      @search[:count] = results.size

      if results.size > 0
        results.sort!{|a,b| b[:count] <=> a[:count]}
        max = results.first[:count].to_i
        results.each{|r| r[:pertinence] = (max.zero? ? 0 : (100*r[:count]/max).to_i)}
      end

      @search[:records] = results[((page-1) * per_page)..(page * per_page - 1)]
      @search[:last_page] = (@search[:count].to_f / per_page).ceil

      if @search[:records].size.zero? and page > 1
        redirect_to(:q => params[:q], :page => 1)
      end
      end
      params[:page] = page
    end
  end

end

