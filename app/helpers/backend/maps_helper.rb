# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  module MapsHelper
    # Raw map for given resource
    def map(resources, options = {}, html_options = {}, &_block)
      resources = [resources] unless resources.respond_to?(:each)
      shape_method = options[:shape_method] || :shape

      global = nil
      options[:geometries] = resources.collect do |resource|
        hash = (block_given? ? yield(resource) : { name: resource.name, shape: resource.send(shape_method) })
        hash[:url] ||= url_for(controller: "/backend/#{resource.class.name.tableize}", action: :show, id: resource.id)
        if hash[:shape]
          global = (global ? global.merge(hash[:shape]) : Charta.new_geometry(hash[:shape]))
          hash[:shape] = Charta.new_geometry(hash[:shape]).transform(:WGS84).to_json_object
        end
        hash
      end

      # Box
      options[:box] ||= {}
      options[:box][:height] ||= 480

      # View box
      if global
        options[:view] ||= {}
        options[:view][:bounding_box] = global.bounding_box.to_a
      end

      content_tag(:div, nil, html_options.merge(data: { map: options.jsonize_keys.to_json }))
    end

    def mini_map(resources, options = {}, html_options = {}, &block)
      options[:box] ||= {}
      options[:box] = { width: 300, height: 300 }.merge(options[:box])
      html_options[:class] ||= ''
      html_options[:class] << ' picture mini-map'
      map(resources, options, html_options, &block)
    end

    def importer_form(imports = [])
      form_tag({ controller: '/backend/map_editors', action: :upload }, method: :post, multipart: true, remote: true, authenticity_token: true, data: { importer_form: 'true' }) do
        content_tag(:div, nil, id: 'alert', class: 'row alert-danger') +
          content_tag(:div, class: 'row') do
            imports.collect.with_index do |k, i|
              content_tag(:div, class: 'choice-padding') do
                radio_button_tag(:importer_format, k, (i.zero? ? true : false)) + label_tag("importer_format_#{k}".to_sym, k)
              end
            end.join.html_safe
          end + content_tag(:div, class: 'row') do
                  file_field_tag(:import_file) + content_tag(:span, content_tag(:i), class: 'spinner-loading', data: { importer_spinner: 'true' })
                end
      end
    end

    def shape_field_tag(name, value = nil, options = {})
      geometry = Charta.new_geometry(value)
      box ||= {}
      options[:box] ||= {}
      options[:data][:map_editor] ||= {}
      if options[:data][:map_editor].key? :customClass
        box[:width] = options[:box][:width]
        box[:height] = options[:box][:height]
      else
        box[:width] = options[:box][:width] || 360
        box[:height] = options[:box][:height] || 240
      end
      # FIXME: map_editors options cannot be in data/map_editors because it's pleonastic
      options[:data][:map_editor][:controls] ||= {}
      options[:data][:map_editor][:controls][:importers] ||= { formats: %i[gml kml geojson] }

      if options[:data][:map_editor][:controls].key? :importers
        options.deep_merge!(data: { map_editor: { controls: { importers: { content: importer_form(options[:data][:map_editor][:controls][:importers][:formats]) } } } })
      end

      options[:data][:map_editor][:back] ||= MapLayer.available_backgrounds.collect(&:to_json_object)

      options.deep_merge!(data: { map_editor: { edit: geometry.to_json_object } }) unless value.nil?
      text_field_tag(name, value, options.deep_merge(data: { map_editor: { box: box.jsonize_keys } }))
    end

    # Use model_map to 'resources' map from current controller
    def main_resources_map(options = {}, &block)
      resources_map(options.deep_merge(main: true), &block)
    end

    # Use model_map to 'resources' map from current controller
    def resources_map(options = {}, &block)
      model_map(resource_model.where.not(id: nil), options, &block)
    end

    # A module map displays an ActiveRecord::Relation as map. Model must have
    # a shape method and a name method. Methods are configurable through
    # options (:shape_method and :label_method)
    # the area unit could be given with options :area_unit
    def model_map(records, options = {}, &block)
      return nil unless records.any?
      klass = records.first.class
      controller = klass.model_name.plural
      label_method = options.delete(:label_method) || :name
      shape_method = options.delete(:shape_method) || :shape
      popup = options.delete(:popup)
      options[:id] ||= klass.model_name.human
      data = records.map do |record|
        if popup.respond_to?(:call)
          feature = popup.call(record)
        elsif popup.is_a?(String)
          feature = render popup, object: record, resource: record
        else
          area_unit = options[:area_unit] || :hectare
          content = []
          # content << { label: klass.human_attribute_name(label_method), value: record.send(label_method) }
          content << { label: Nomen::Indicator.find(:net_surface_area).human_name,
                       value: record.net_surface_area.in(area_unit).round(3).l }
          content << content_tag(:div, class: 'btn-group') do
            link_to(:show.tl, { controller: controller, action: :show, id: record.id }, class: 'btn btn-default') +
              link_to(:edit.tl, { controller: controller, action: :edit, id: record.id }, class: 'btn btn-default')
          end
          feature = { popup: { content: content, header: true } }
        end
        feature[:name] ||= record.send(label_method)
        feature[:shape] ||= record.send(shape_method)
        feature
      end
      collection_map(data, options, &block)
    end

    # Build a map with a given list of object
    def collection_map(data, options = {}, &_block)
      html_options = {}
      return nil unless data.any?
      backgrounds = options.delete(:backgrounds) || []
      options = {
        controls: {
          zoom: true,
          scale: true,
          fullscreen: true,
          layer_selector: true
        }
      }.deep_merge(options)
      if options.delete(:main)
        options[:box] ||= {}
        options[:box][:height] = '100%'
        html_options[:class] = 'map-fullwidth'
      end
      visualization(options, html_options) do |v|
        backgrounds.each do |b|
          v.background(b)
        end
        v.serie :main, data
        if block_given?
          yield v
        else
          layer_options = options[:layer_options] || {}
          layer_options[:fill_color] = options[:color] if options[:color]
          v.simple options[:id] || :items, :main, layer_options
        end
      end
    end
  end
end
