# frozen_string_literal: true

RSpec.describe TestBudget::Budget do
  it "loads configuration from YAML" do
    write_budget_file(
      "timings_path" => "tmp/results.json",
      "suite" => {"max_duration" => 600},
      "per_test_case" => {"default" => 3, "system" => 10, "model" => 2},
      "allowlist" => [{"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy test", "expires_on" => (Date.today + 365).to_s}]
    ) do |path|
      budget = described_class.load(path)

      expect(budget.timings_path).to eq("tmp/results.json")
      expect(budget.suite.max_duration).to eq(600)
      expect(budget.per_test_case.default).to eq(3)
      expect(budget.per_test_case.types).to eq({system: 10, model: 2})
      slow_test = TestBudget::TestCase.new(file: "spec/models/user_spec.rb", name: "User#slow", duration: 1.0, status: "passed", line_number: 4)
      expect(budget.exempt?(slow_test)).to be true
    end
  end

  it "converts type keys to symbols" do
    write_budget_file(
      "timings_path" => "tmp/results.json",
      "per_test_case" => {"request" => 3}
    ) do |path|
      budget = described_class.load(path)

      expect(budget.per_test_case.types).to eq({request: 3})
    end
  end

  it "raises Error for missing file" do
    expect { described_class.load("nonexistent.yml") }.to raise_error(TestBudget::Error, /not found/)
  end

  it "raises Error when timings_path is missing" do
    write_budget_file("per_test_case" => {"default" => 5}) do |path|
      expect { described_class.load(path) }.to raise_error(TestBudget::Error, /timings_path/)
    end
  end

  it "raises Error when no limits are configured" do
    write_budget_file("timings_path" => "tmp/results.json") do |path|
      expect { described_class.load(path) }.to raise_error(TestBudget::Error, /No limits configured/)
    end
  end

  it "does not raise when only suite is configured" do
    write_budget_file("timings_path" => "tmp/results.json", "suite" => {"max_duration" => 600}) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "does not raise when only per_test_case default is configured" do
    write_budget_file("timings_path" => "tmp/results.json", "per_test_case" => {"default" => 5}) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "does not raise when only per_test_case type limits are configured" do
    write_budget_file("timings_path" => "tmp/results.json", "per_test_case" => {"model" => 2}) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "loads without error when allowlist is nil" do
    write_budget_file(
      "timings_path" => "tmp/results.json",
      "per_test_case" => {"default" => 5},
      "allowlist" => nil
    ) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "loads without error when suite is nil" do
    write_budget_file(
      "timings_path" => "tmp/results.json",
      "per_test_case" => {"default" => 5},
      "suite" => nil
    ) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "loads without error when per_test_case is nil" do
    write_budget_file(
      "timings_path" => "tmp/results.json",
      "suite" => {"max_duration" => 600},
      "per_test_case" => nil
    ) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  describe "#inflate_by" do
    it "inflates suite max_duration by the given percent" do
      budget = build_budget(suite: {max_duration: 10}, per_test_case: {default: 2})

      inflated = budget.inflate_by(0.1)

      expect(inflated.suite.max_duration).to eq(11.0)
    end

    it "inflates per_test_case default by the given percent" do
      budget = build_budget(per_test_case: {default: 2})

      inflated = budget.inflate_by(0.1)

      expect(inflated.per_test_case.default).to eq(2.2)
    end

    it "inflates per_test_case types values by the given percent" do
      budget = build_budget(per_test_case: {default: 2, types: {system: 10, model: 5}})

      inflated = budget.inflate_by(0.1)

      expect(inflated.per_test_case.types).to eq({system: 11.0, model: 5.5})
    end

    it "handles nil limits" do
      budget = build_budget(per_test_case: {default: 2})

      inflated = budget.inflate_by(0.1)

      expect(inflated.suite.max_duration).to be_nil
      expect(inflated.per_test_case.default).to eq(2.2)
    end

    it "handles nil per_test_case default" do
      budget = build_budget(suite: {max_duration: 10}, per_test_case: {types: {system: 10}})

      inflated = budget.inflate_by(0.1)

      expect(inflated.per_test_case.default).to be_nil
      expect(inflated.per_test_case.types).to eq({system: 11.0})
    end

    it "preserves allowlist, path, and timings_path unchanged" do
      budget = build_budget(
        per_test_case: {default: 2},
        allowlist: ["spec/models/user_spec.rb -- example"]
      )

      inflated = budget.inflate_by(0.1)

      expect(inflated.path).to eq(budget.path)
      expect(inflated.timings_path).to eq(budget.timings_path)
      expect(inflated.allowlist).to eq(budget.allowlist)
    end
  end

  describe "#exempt?" do
    it "returns false when entry is expired" do
      budget = build_budget(per_test_case: {default: 2})
      expired_entry = build_entry(test_case_key: "spec/models/user_spec.rb -- example", expires_on: Date.today - 1)
      budget.allowlist.instance_variable_get(:@entries) << expired_entry

      test_case = build_test_case(duration: 3.0)

      expect(budget.exempt?(test_case)).to be false
    end

    it "returns true when entry is not expired" do
      budget = build_budget(
        per_test_case: {default: 2},
        allowlist: ["spec/models/user_spec.rb -- example"]
      )

      test_case = build_test_case(duration: 3.0)

      expect(budget.exempt?(test_case)).to be true
    end
  end

  describe "#prune_allowlist" do
    def budget_with_results(allowlist: [])
      write_timings_file([
        {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid",
         "run_time" => 1.0, "status" => "passed", "line_number" => 4}
      ]) do |timings_path|
        data = {
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5}
        }
        data["allowlist"] = allowlist unless allowlist.empty?
        write_budget_file(data) do |path|
          yield described_class.load(path)
        end
      end
    end

    it "removes obsolete entries and saves file" do
      budget_with_results(
        allowlist: [
          {"test_case" => "spec/models/old_spec.rb -- gone test", "reason" => "Stale", "expires_on" => (Date.today + 365).to_s},
          {"test_case" => "spec/models/user_spec.rb -- User is valid", "reason" => "Within budget now", "expires_on" => (Date.today + 365).to_s}
        ]
      ) do |budget|
        removed = budget.prune_allowlist

        expect(removed.size).to eq(2)
        config = YAML.safe_load_file(budget.path)
        expect(config).not_to have_key("allowlist")
      end
    end

    it "does not rewrite file when nothing to prune" do
      write_timings_file([
        {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid",
         "run_time" => 10.0, "status" => "passed", "line_number" => 4}
      ]) do |timings_path|
        write_budget_file(
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5},
          "allowlist" => [
            {"test_case" => "spec/models/user_spec.rb -- User is valid", "reason" => "Still needed", "expires_on" => (Date.today + 365).to_s}
          ]
        ) do |path|
          budget = described_class.load(path)
          mtime_before = File.mtime(path)

          removed = budget.prune_allowlist

          expect(removed).to be_empty
          expect(File.mtime(path)).to eq(mtime_before)
        end
      end
    end
  end

  describe "#add_to_allowlist" do
    def budget_with_results(allowlist: [])
      write_timings_file([
        {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid",
         "run_time" => 1.0, "status" => "passed", "line_number" => 4}
      ]) do |timings_path|
        data = {
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5}
        }
        data["allowlist"] = allowlist unless allowlist.empty?
        write_budget_file(data) do |path|
          yield described_class.load(path)
        end
      end
    end

    it "resolves locator and persists entry to YAML" do
      budget_with_results do |budget|
        entry = budget.add_to_allowlist("spec/models/user_spec.rb:4", reason: "Legacy test")

        expect(entry).to be_a(TestBudget::Allowlist::Entry)
        expect(entry.test_case_key).to eq("spec/models/user_spec.rb -- User is valid")
        expect(entry.reason).to eq("Legacy test")
        expect(entry.expires_on).to eq(Date.today + TestBudget::Budget::DEFAULT_EXPIRATION_DAYS)
        config = YAML.safe_load_file(budget.path)
        expect(config["allowlist"].size).to eq(1)
        expect(config["allowlist"].first).to eq(
          "test_case" => "spec/models/user_spec.rb -- User is valid",
          "reason" => "Legacy test",
          "expires_on" => (Date.today + TestBudget::Budget::DEFAULT_EXPIRATION_DAYS).to_s
        )
      end
    end

    it "appends to existing allowlist entries" do
      budget_with_results(
        allowlist: [{"test_case" => "spec/models/post_spec.rb -- Post is valid", "reason" => "Slow by design", "expires_on" => (Date.today + 365).to_s}]
      ) do |budget|
        budget.add_to_allowlist("spec/models/user_spec.rb:4", reason: "Legacy test")

        config = YAML.safe_load_file(budget.path)
        expect(config["allowlist"].size).to eq(2)
      end
    end

    it "written YAML is valid and re-loadable" do
      budget_with_results do |budget|
        budget.add_to_allowlist("spec/models/user_spec.rb:4", reason: "Legacy test")

        expect { described_class.load(budget.path) }.not_to raise_error
      end
    end
  end
end
