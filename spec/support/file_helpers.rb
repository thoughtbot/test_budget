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

  def write_budget_file(data, &block)
    with_tempfile([".test_budget", ".yml"], data.to_yaml, &block)
  end

  def write_results_file(examples, &block)
    with_tempfile(["rspec_results", ".json"], JSON.generate("examples" => examples), &block)
  end

  private

  def with_tempfile(name, content)
    file = Tempfile.create(name)
    file.write(content)
    file.flush
    yield file.path
  ensure
    file&.close
    File.unlink(file.path) if file
  end
end
