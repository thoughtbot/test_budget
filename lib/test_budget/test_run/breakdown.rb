# frozen_string_literal: true

module TestBudget
  class TestRun
    class Breakdown < Data.define(:test_run)
      TABLE = Table.new([
        ["Test Type", :left],
        ["Count", :right],
        ["%", :right],
        ["Duration", :right],
        ["%", :right]
      ])

      def to_s
        groups = test_run.groups.sort_by { |g| -g.duration }
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
