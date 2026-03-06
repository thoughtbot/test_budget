# frozen_string_literal: true

require "tempfile"
require "yaml"
require "json"

module FileHelpers
  def build_budget(per_test_case: nil, suite: nil, allowlist: [])
    TestBudget::Budget.new(
      path: nil,
      results_path: nil,
      suite: TestBudget::Budget::Suite.new(max_duration: suite&.dig(:max_duration)),
      per_test_case: TestBudget::Budget::PerTestCase.new(
        default: per_test_case&.dig(:default),
        types: per_test_case&.dig(:types) || {}
      ),
      allowlist: TestBudget::Allowlist.new(
        allowlist.map { |key| {"test_case" => key, "reason" => "test"} }
      )
    )
  end

  def write_budget_file(data)
    file = Tempfile.new([".test_budget", ".yml"])
    file.write(data.to_yaml)
    file.close
    file.path
  end

  def write_results_file(examples)
    file = Tempfile.new(["rspec_results", ".json"])
    file.write(JSON.generate("examples" => examples))
    file.close
    file.path
  end
end
