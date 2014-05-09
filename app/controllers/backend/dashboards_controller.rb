# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::DashboardsController < BackendController

  def index
  end

  for menu in Ekylibre::Modules.hash.keys
    code  = "def #{menu}\n"
    # code << " notify_warning_now(:dashboard_is_being_developed)"
    # code << "  render :file => 'backend/dashboards/#{menu}', :layout => dialog_or_not\n"
    code << "end\n"
    class_eval code
  end

  def sandbox
  end

  SIMILAR_LETTERS = [
                     %w(C Ç),
                     %w(A Á À Â Ä Ǎ Ă Ā Ã Å),
                     %w(Æ Ǽ Ǣ),
                     %w(E É È Ė Ê Ë Ě Ĕ Ē),
                     %w(I Í Ì İ Î Ï Ǐ Ĭ Ī Ĩ),
                     %w(O Ó Ò Ô Ö Ǒ Ŏ Ō Õ Ő),
                     %w(U Ú Ù Û Ü Ǔ Ŭ Ū Ũ Ű Ů),
                     %w(Y Ý Ỳ Ŷ Ÿ Ȳ Ỹ),
                     %w(c ç),
                     %w(a á à â ä ǎ ă ā ã å),
                     %w(æ ǽ ǣ),
                     %w(e é è ė ê ë ě ĕ ē),
                     %w(i í ì i î ï ǐ ĭ ī ĩ),
                     %w(o ó ò ô ö ǒ ŏ ō õ ő),
                     %w(u ú ù û ü ǔ ŭ ū ũ ű ů),
                     %w(ý ỳ ŷ ÿ ȳ ỹ)
  ]


  # Global search method is put there for now waiting for a better place
  # This action permits to search across.all the main data of the application
  # TODO: Clean this!!!
  def search
    per_page = 10
    page = params[:page].to_i
    page = 1 if page.zero?
    # Create filter
    words = params[:q].to_s.gsub(/[\'\"\(\)\[\]\=\-\|\{\}]+/, ' ').strip.split(/\s+/).collect do |w|
      for group in SIMILAR_LETTERS
        exp = "(" + group.join("|") + ")"
        w.gsub!(Regexp.new(exp), exp)
      end
      w
    end

    pertinence = "1"
    if words.count > 0
      # max is the maximal points count that can be obtained for a key word
      # here it's equivalent to find 5 times the sole word.
      max = 4 * 5
      pertinence = "ROUND(100.0 * CAST((" + words.collect do |word|
        points = [word, "#{word}\\\\M", "#{word}\\\\M", "\\\\M#{word}\\\\M"].collect do |exp|
          # Count occurrences
          "ARRAY_LENGTH(REGEXP_SPLIT_TO_ARRAY(indexer, E'#{exp}', 'i'), 1)-1"
        end.join("+")
        "(CASE WHEN (#{points}) > #{max} THEN #{max} ELSE (#{points}) END)"
      end.join(" * ") + ") AS FLOAT)/#{max ** words.count}.0)"
    end

    filtered = "SELECT record_id, record_type, title, indexer, (" + pertinence + ") AS pertinence FROM (#{@@centralizing_query}) AS centralizer GROUP BY record_type, record_id, title, indexer"

    filter  = " FROM (#{filtered}) AS filtered"
    filter << " WHERE filtered.pertinence > 0"

    @search = {}

    # Count results
    query = "SELECT count(filtered.record_id) AS total_count #{filter}"
    @search[:count] = Ekylibre::Record::Base.connection.select_value(query).to_i
    @search[:last_page] = (@search[:count].to_f / per_page).ceil

    # Select results
    query = "SELECT record_id, record_type, title, indexer, pertinence #{filter}"
    query << " ORDER BY filtered.pertinence DESC, title"
    query << " LIMIT #{per_page}"
    query << " OFFSET #{per_page * (page - 1)}"
    @search[:records] = Ekylibre::Record::Base.connection.select_all(query)

    if @search[:count] == 1
      record = @search[:records].first
      redirect_to controller: record['record_type'].tableize, action: :show, id: record['record_id'].to_i, :q => params[:q]
      return
    end

    # @search[:query] = query

    @search[:words] = words

    if @search[:count].zero? and page > 1
      redirect_to(action: :search, :q => params[:q], :page => 1)
    end
    params[:page] = page
    t3e :searched => params[:q]
  end


  private

  def self.build_centralizing_query
    excluded = [:account_balance, :affair, :financial_asset_depreciation, :custom_field_choice, :deposit_item, :document_template, :inventory_item, :listing_node_item, :preference, :tax_declaration, :transfer]

    queries = []
    for model_name in Ekylibre::Schema.models
      next if excluded.include?(model_name)
      model = model_name.to_s.camelcase.constantize
      next unless model.superclass == Ekylibre::Record::Base
      cols = model.columns_definition.keys
      title = [:label, :name, :full_name, :reason, :code, :number].detect{|x| cols.include?(x.to_s)}
      next unless title
      columns = model.columns_definition.values.delete_if do |c|
        [:created_at, :creator_id, :depth, :id, :lft, :lock_version,
         :position, :rights, :rgt, :type, :updated_at, :updater_id].include?(c[:name]) or
          [:boolean, :spatial].include? c[:type] or
          c[:name].to_s =~ /\_file_size$/ or
          c[:name].to_s =~ /\_type$/ or
          c[:name].to_s =~ /\_id$/
      end.collect do |c|
        name = c[:name]
        if model.respond_to?(name) and model.send(name).respond_to?(:options) and options = model.send(name).send(:options) and options.size > 0
          "CASE " + options.collect{|l, v| "WHEN #{name} = '#{v}' THEN '" + l.to_s.gsub("'", "''") + " '"}.join(" ") + " ELSE '' END"
        else
          "COALESCE(#{name} || ' ', '')"
        end
      end
      if columns.any?
        query =  "SELECT #{Ekylibre::Record::Base.connection.quote(model.model_name.human)} || ' ' || " + columns.join(" || ") + " AS indexer, #{title} AS title, " + (model.columns_definition[:type] ? 'type' : "'#{model.name}'") + " AS record_type, id AS record_id FROM #{model.table_name}"
        queries << query
      end
    end

    @@centralizing_query = "(" + queries.join(") UNION ALL (") + ")"
  end

  build_centralizing_query

end
