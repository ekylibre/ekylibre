module Ekylibre
  module FirstRun
    class Manifest

      def self.store(hash, *keys)
        key = keys.first
        if hash.is_a?(Hash)
          return rec(hash[key], *keys[1..-1]) if keys.count > 1
          return hash[key]
        end
        return nil
      end



      def initialize
        @files = {}
        @config = Ekylibre::Support::Tree.new
      end

      def add_file(*args)
        options = args.extract_options!
        file = args.delete_at(-1)


        doc = path.dirname.join(spec[:imports][import][param])
        name = "#{param}#{doc.extname}"
        files["imports/#{import}/#{name}"] = doc
        @config[*args] = name
        @files[(args + [name]).join("/")] = file

      end

      def [](name)
        @config[name]
      end

      def []=(name, value)
        @config[name] = value
      end

      def store(*args)
        options = args.extract_options!
        value = args.delete_at(-1)
        if value.is_a?(Pathname)
          name = value.basename.to_s.mb_char.downcase.gsub(/\W/, '_')
          path = args[0..-2] + [name]
          args[-1] = name
          @files[path.join('/')] = file
          Manifest.store(@config, *args)
        else
          Manifest.store(@config, *args)
        end
      end


      def build(file)
        Zip::OutputStream.open(file) do |zile|
          zile.put_next_entry('mimetype', nil, nil, Zip::Entry::STORED)
          zile << Mime::FRA

          zile.put_next_entry('manifest.yml')
          zile << @config.deep_stringify_keys.to_yaml

          for dest, src in @files
            zile.put_next_entry(dest)
            zile << File.read(src)
          end
        end
      end

      def method_missing(symbol, *args)
        if symbol.to_s =~ /\=\z/

        else

        end
      end

      private

      def set(*args)
        @config.set(
      end

    end
  end
end
