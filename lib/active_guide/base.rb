module ActiveGuide
  # This class defines a DSL in order to define guides for
  # various purpose like best pratices
  #
  #   ActiveGuide::Base.new :cap_2016 do
  #     result :penalty_percentage
  #     before do
  #       # Some cool code
  #       variables.penalty_percentage = 0
  #     end
  #     group :animals do
  #       test :stuff_well_done, -> { Stuff.well_done? }
  #       question :have_you_done_this_task, before: -> { Task.any? }
  #       test :other_stuff_done, if: :stuff_well_done do
  #         validate do
  #           OtherStuff.done? and ManyOtherStuff.done?
  #         end
  #         after do |validated|
  #           unless validated
  #             variables.penalty_percentage += 1
  #           end
  #         end
  #       end
  #     end
  #   end
  #
  class Base
    cattr_reader :root

    class << self

      delegate :result, :group, :question, :test, :before, :after, :accept, to: :root

      def inherited(subclass)
        @@root = Group.new(nil, :root)
        subclass.import_from(self)
      end

      def import_from(guide)
        if guide.root
          guide.root.items.each do |item|
            @@root.add_item item.dup
          end
        end
      end

      # Run an analyses with default SimpleAnalyzer by default
      def run(*args)
        options  = args.extract_options!
        analyzer = args.shift || options[:analyzer]
        analyzer ||= SimpleAnalyzer.new
        analyzer.run(self, options)
      end

    end

  end
end
