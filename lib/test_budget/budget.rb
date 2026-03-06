# frozen_string_literal: true

require "yaml"

module TestBudget
  class Budget < Data.define(:results_path, :suite, :per_test_case, :allowlist)
    Suite = Data.define(:max_duration)
    PerTestCase = Data.define(:default, :by_type)

    def self.load(path)
      config = YAML.safe_load_file(path) || {}
      suite_config = config.fetch("suite", {}) || {}
      per_test_case_config = config.fetch("per_test_case", {}) || {}
      by_type = (per_test_case_config["by_type"] || {}).transform_keys(&:to_sym)

      budget = new(
        results_path: config["results_path"],
        suite: Suite.new(max_duration: suite_config["max_duration"]),
        per_test_case: PerTestCase.new(
          default: per_test_case_config["default"],
          by_type: by_type
        ),
        allowlist: Set.new(config.fetch("allowlist", []))
      )

      raise TestBudget::Error, "results_path is required in budget file" unless budget.results_path
      raise TestBudget::Error, "No limits configured. Set suite.max_duration or per_test_case limits" unless budget.limits_set?

      budget
    rescue Errno::ENOENT
      raise TestBudget::Error, "Budget file not found: #{path}"
    end

    def allowed?(test_case)
      allowlist.include?(test_case.key)
    end

    def limits_set?
      suite.max_duration || per_test_case.default || per_test_case.by_type.any?
    end
  end
end
