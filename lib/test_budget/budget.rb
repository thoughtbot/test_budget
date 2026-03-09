# frozen_string_literal: true

require "date"
require "yaml"

module TestBudget
  class Budget < Data.define(:path, :timings_path, :suite, :per_test_case, :allowlist)
    DEFAULT_EXPIRATION_DAYS = 60

    Suite = Data.define(:max_duration)
    PerTestCase = Data.define(:default, :types)

    def self.estimate(...) = Estimate.new(...).generate

    def self.load(path)
      config = YAML.safe_load_file(path) || {}
      suite_config = config["suite"] || {}
      per_test_case_config = config["per_test_case"] || {}
      types = per_test_case_config.except("default").transform_keys(&:to_sym)

      budget = new(
        path: path,
        timings_path: config["timings_path"],
        suite: Suite.new(max_duration: suite_config["max_duration"]),
        per_test_case: PerTestCase.new(
          default: per_test_case_config["default"],
          types: types
        ),
        allowlist: Allowlist.new(config["allowlist"] || [])
      )

      raise TestBudget::Error, "timings_path is required in budget file" unless budget.timings_path
      raise TestBudget::Error, "No limits configured. Set suite.max_duration or per_test_case limits" unless budget.limits_set?

      budget
    rescue Errno::ENOENT
      raise TestBudget::Error, "Budget file not found: #{path}"
    end

    def exempt?(test_case)
      entry = allowlist.allowed?(test_case.key)

      entry && !entry.expired?
    end

    def limit_for(test_case)
      per_test_case.types[test_case.type] || per_test_case.default
    end

    def add_to_allowlist(locator, reason:)
      test_run = Parser::Rspec.parse(timings_path)
      test_case = TestCase.find_by_location!(test_run.test_cases, locator)

      allowlist.add(test_case.key, reason: reason, expires_on: Date.today + DEFAULT_EXPIRATION_DAYS).tap { save }
    end

    def prune_allowlist
      test_run = Parser::Rspec.parse(timings_path)
      removed = allowlist.prune(test_run, self)
      save if removed.any?
      removed
    end

    def limits_set?
      suite.max_duration || per_test_case.default || per_test_case.types.any?
    end

    def save
      File.write(path, YAML.dump(to_h))
    end

    private

    def to_h
      deep_compact_blank(
        "timings_path" => timings_path,
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
