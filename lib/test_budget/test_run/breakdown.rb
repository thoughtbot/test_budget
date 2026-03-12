# frozen_string_literal: true

module TestBudget
  class TestRun
    class Breakdown < Data.define(:test_run, :sort)
      SORT_OPTIONS = %i[duration count type].freeze
      TABLE = Table.new([
        ["Test Type", :left],
        ["Count", :right],
        ["%", :right],
        ["Duration", :right],
        ["%", :right]
      ])

      def initialize(test_run:, sort: :duration) = super

      def to_s
        groups = sort_groups(test_run.groups)
        return "No test cases found.\n" if groups.empty?

        rows = groups.map { |g|
          [
            g.type,
            g.count.to_s,
            "%.1f%%" % g.percent_count,
            format_duration(g.duration),
            "%.1f%%" % g.percent_duration
          ]
        }

        TABLE.render(
          rows,
          footer: ["Total", test_run.size.to_s, "", format_duration(test_run.total_time), ""]
        )
      end

      private

      def sort_groups(groups)
        case sort
        when :count then groups.sort_by { |g| [-g.count, -g.duration] }
        when :type then groups.sort_by { |g| g.type.to_s }
        else groups.sort_by { |g| -g.duration }
        end
      end

      def format_duration(seconds)
        if seconds >= 60
          minutes = (seconds / 60).to_i
          secs = (seconds % 60).round
          "#{minutes}m #{secs}s"
        else
          "#{seconds.round}s"
        end
      end
    end
  end
end
