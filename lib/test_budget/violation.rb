# frozen_string_literal: true

module TestBudget
  Violation = Data.define(:test_case, :duration, :limit, :kind) do
    def message
      if kind == :suite
        "Suite total time (%.2fs) exceeds limit (%.2fs)" % [duration, limit]
      else
        "#{test_case.key} (%.2fs) exceeds #{test_case.type} limit (%.2fs)" % [duration, limit]
      end
    end

    def allowlist_snippet
      return nil if kind == :suite

      "- test_case: \"#{test_case.key}\""
    end
  end
end
