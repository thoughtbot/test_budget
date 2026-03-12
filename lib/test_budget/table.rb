# frozen_string_literal: true

module TestBudget
  class Table
    def initialize(columns)
      @columns = columns
    end

    def render(rows, footer:)
      header = format_row(@columns.map(&:first))
      separator = "-" * row_width
      body = rows.map { |cells| format_row(cells) }

      [header, separator, *body, separator, format_row(footer)].join("\n") + "\n"
    end

    private

    def format_row(cells)
      parts = @columns.zip(cells).map { |(_, width, align), cell|
        case align
        when :right then cell.to_s.rjust(width)
        else cell.to_s.ljust(width)
        end
      }

      parts.join(" ")
    end

    def row_width
      @columns.sum { |_, width, _| width } + @columns.size - 1
    end
  end
end
