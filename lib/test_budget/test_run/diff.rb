# frozen_string_literal: true

module TestBudget
  class TestRun
    class Diff < Data.define(:before, :after)
      TABLE = Table.new([
        ["Test Type", :left],
        ["Δ Count", :right],
        ["%", :right],
        ["Δ Duration", :right],
        ["%", :right]
      ])

      def to_s
        rows = delta_rows
        return "" if rows.empty?

        TABLE.render(
          rows.map { |r| format_row(r) },
          footer: format_row(total)
        )
      end

      private

      NULL_GROUP = Group.new(type: :null, count: 0, duration: 0.0, test_run: nil)

      def delta_rows
        full_outer_join(before.groups, after.groups, by: :type, default: NULL_GROUP)
          .map { |type, b, a| Delta.new(label: type, before: b, after: a) }
          .reject(&:zero?)
          .sort_by { |delta| [-delta.duration.abs, -delta.count.abs] }
      end

      def total = Delta.new(label: "Total", before: before, after: after)

      def format_row(row) = [
        row.label,
        Format.signed_int(row.count),
        Format.percent(row.percent_count),
        Format.signed_duration(row.duration),
        Format.percent(row.percent_duration)
      ]

      def full_outer_join(left, right, by:, default:)
        left_index = left.to_h { |item| [item.public_send(by), item] }
        right_index = right.to_h { |item| [item.public_send(by), item] }

        (left_index.keys | right_index.keys).map do |key|
          [key, left_index.fetch(key, default), right_index.fetch(key, default)]
        end
      end
    end
  end
end
