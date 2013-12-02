module ActiveList

  module Definition

    class Table
      attr_reader :name, :model, :options, :id, :columns, :parameters

      def initialize(name, model = nil, options = {})
        @name    = name
        @model   = model || name.to_s.classify.constantize
        @options = options
        @paginate = !(@options[:pagination]==:none || @options[:paginate].is_a?(FalseClass))
        @options[:renderer] ||= :simple_renderer
        @options[:per_page] = 20 if @options[:per_page].to_i <= 0
        @options[:page] = 1 if @options[:page].to_i <= 0
        @columns = []
        @id = ActiveList.new_uid
      end

      def new_column_id
        @current_column_id ||= 0
        id = @current_column_id.to_s(36).to_sym
        @current_column_id += 1
        return id
      end

      def model_columns
        @model.columns_definition.values
      end

      def sortable_columns
        @columns.select{|c| c.sortable?}
      end

      def exportable_columns
        @columns.select{|c| c.exportable?}
      end

      def children
        @columns.map(&:child)
      end

      def paginate?
        @paginate
      end

      # Retrieves all columns in database
      def table_columns
        cols = self.model_columns.map(&:name)
        @columns.select{|c| c.is_a? DataColumn and cols.include? c.name.to_s}
      end

      def data_columns
        @columns.select{|c| c.is_a? DataColumn}
      end

      def hidden_columns
        self.data_columns.select(&:hidden?)
      end

      # Compute includes Hash
      def reflections
        hash = []
        for column in self.columns
          if column.respond_to?(:reflection)
            unless hash.detect{|r| r.name == column.reflection.name }
              hash << column.reflection 
            end
          end
        end
        return hash
      end


      # Add a new method in Table which permit to define text_field columns
      def text_field(name, options = {})
        add :text_field, name, options
      end

      # Add a new method in Table which permit to define check_box columns
      def check_box(name, options = {})
        add :check_box, name, options
      end

      # Add a new method in Table which permit to define action columns
      def action(name, options = {})
        add :action, name, options
      end

      # # Add a new method in Table which permit to define data columns
      # def attribute(name, options = {})
      #   add :attribute, name, options
      # end

      # # Add a column referencing an association
      # def association(name, options = {})
      #   options[:through] ||= name
      #   add :association, name, options
      # end

      # Add a new method in Table which permit to define data columns
      def column(name, options = {})
        if @model.reflect_on_association(name)
          options[:through] ||= name
          add :association, name, options
        elsif @model.reflect_on_association(options[:through])
          options[:label_method] ||= name
          add :association, name, options
        else
          add :attribute, name, options
        end
      end



      def load_default_columns
        for column in self.model_columns
          reflections = @model.reflections.values.select{|r| r.macro == :belongs_to and r.foreign_key.to_s == column.name.to_s}
          if reflections.size == 1
            reflection = reflections.first
            columns = reflection.class_name.constantize.columns.collect{ |c| c.name.to_s }
            self.column([:label, :name, :code, :number].detect{ |l| columns.include?(l.to_s) }, :through => reflection.name, :url => true)
          else
            self.column(column.name)
          end
        end
        return true
      end

      private

      # Checks and add column
      def add(type, name, options = {})
        klass = "ActiveList::Definition::#{type.to_s.camelcase}Column".constantize rescue nil
        if klass and klass < AbstractColumn
          unless name.is_a?(Symbol)
            raise ArgumentError, "Name of a column must be a Symbol (got #{name.inspect})."
          end
          if @columns.detect{|c| c.name == name}
            raise ArgumentError, "Column name must be unique. #{name.inspect} is already used in #{self.name}"
          end
          @columns << klass.new(self, name, options)
        else
          raise ArgumentError, "Invalid column type: #{type.inspect}"
        end
      end


    end


  end

end
