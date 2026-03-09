# frozen_string_literal: true

module TestBudget
  Violation = Data.define(:test_case, :duration, :limit, :kind) do
    def message
      if kind == :suite
        "Suite total time (%.2fs) exceeds limit (%.2fs)" % [duration, limit]
      else
        format("%s (%.2fs) exceeds %s limit (%.2fs)", test_case.key, duration, test_case.type, limit)
      end
    end

    def locator
      return nil if kind == :suite

      "#{test_case.file}:#{test_case.line_number}"
    end
  end
end
