# frozen_string_literal: true

require "yaml"

module TestBudget
  class Budget < Data.define(:path, :results_path, :suite, :per_test_case, :allowlist)
    Suite = Data.define(:max_duration)
    PerTestCase = Data.define(:default, :types)

    def self.load(path)
      config = YAML.safe_load_file(path) || {}
      suite_config = config["suite"] || {}
      per_test_case_config = config["per_test_case"] || {}
      types = per_test_case_config.except("default").transform_keys(&:to_sym)

      budget = new(
        path: path,
        results_path: config["results_path"],
        suite: Suite.new(max_duration: suite_config["max_duration"]),
        per_test_case: PerTestCase.new(
          default: per_test_case_config["default"],
          types: types
        ),
        allowlist: Allowlist.new(config["allowlist"] || [])
      )

      raise TestBudget::Error, "results_path is required in budget file" unless budget.results_path
      raise TestBudget::Error, "No limits configured. Set suite.max_duration or per_test_case limits" unless budget.limits_set?

      budget
    rescue Errno::ENOENT
      raise TestBudget::Error, "Budget file not found: #{path}"
    end

    def allowed?(test_case)
      allowlist.allowed?(test_case.key)
    end

    def add_to_allowlist(locator, reason:)
      test_cases = Parser::Rspec.parse(results_path)
      test_case = TestCase.find_by_location!(test_cases, locator)

      allowlist.add(test_case.key, reason: reason).tap { save }
    end

    def limits_set?
      suite.max_duration || per_test_case.default || per_test_case.types.any?
    end

    def self.estimate(...) = Estimate.new(...).generate

    def save
      File.write(path, YAML.dump(to_h))
    end

    private

    def to_h
      deep_compact_blank(
        "results_path" => results_path,
        "suite" => {"max_duration" => suite.max_duration},
        "per_test_case" => {
          "default" => per_test_case.default,
          **per_test_case.types.transform_keys(&:to_s)
        },
        "allowlist" => allowlist.to_a.map(&:to_h)
      )
    end

    def deep_compact_blank(hash)
      hash.each_with_object({}) do |(key, value), result|
        value = deep_compact_blank(value) if value.is_a?(Hash)
        next if value.nil?
        next if value.respond_to?(:empty?) && value.empty?
        result[key] = value
      end
    end
  end
end
