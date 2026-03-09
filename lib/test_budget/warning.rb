# frozen_string_literal: true

module TestBudget
  Warning = Data.define(:entry, :kind) do
    def message
      reason_line = entry.reason ? "\nreason: #{entry.reason}" : ""
      "obsolete allowlist entry (#{kind})\n#{entry.test_case_key}#{reason_line}"
    end
  end
end
