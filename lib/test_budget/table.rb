# frozen_string_literal: true

module TestBudget
  class Table
    def initialize(columns)
      @columns = columns
    end

    def render(rows, footer:)
      all_rows = [headers, *rows, footer]
      widths = resolve_widths(all_rows)

      header = format_row(headers, widths)
      body = rows.map { |cells| format_row(cells, widths) }

      [
        horizontal_line("┌", "┬", "┐", widths),
        header,
        horizontal_line("├", "┼", "┤", widths),
        *body,
        horizontal_line("├", "┼", "┤", widths),
        format_row(footer, widths),
        horizontal_line("└", "┴", "┘", widths)
      ].join("\n") + "\n"
    end

    private

    def headers
      @columns.map(&:first)
    end

    def resolve_widths(all_rows)
      @columns.each_with_index.map { |_, i|
        all_rows.map { |row| row[i].to_s.length }.max
      }
    end

    def format_row(cells, widths)
      parts = @columns.zip(cells, widths).map { |(_, alignment), cell, width|
        case alignment
        when :right then cell.to_s.rjust(width)
        else cell.to_s.ljust(width)
        end
      }

      "│ #{parts.join(" │ ")} │"
    end

    def horizontal_line(left, mid, right, widths)
      segments = widths.map { |w| "─" * (w + 2) }
      left + segments.join(mid) + right
    end
  end
end
