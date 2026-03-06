# frozen_string_literal: true

RSpec.describe TestBudget::Budget do
  it "loads configuration from YAML" do
    write_budget_file(
      "results_path" => "tmp/results.json",
      "suite" => {"max_duration" => 600},
      "per_test_case" => {"default" => 3, "system" => 10, "model" => 2},
      "allowlist" => [{"test_case" => "spec/models/user_spec.rb -- User#slow", "reason" => "Legacy test"}]
    ) do |path|
      budget = described_class.load(path)

      expect(budget.results_path).to eq("tmp/results.json")
      expect(budget.suite.max_duration).to eq(600)
      expect(budget.per_test_case.default).to eq(3)
      expect(budget.per_test_case.types).to eq({system: 10, model: 2})
      slow_test = TestBudget::TestCase.new(file: "spec/models/user_spec.rb", name: "User#slow", duration: 1.0, status: "passed", line_number: 4)
      expect(budget.allowed?(slow_test)).to be true
    end
  end

  it "converts type keys to symbols" do
    write_budget_file(
      "results_path" => "tmp/results.json",
      "per_test_case" => {"request" => 3}
    ) do |path|
      budget = described_class.load(path)

      expect(budget.per_test_case.types).to eq({request: 3})
    end
  end

  it "raises Error for missing file" do
    expect { described_class.load("nonexistent.yml") }.to raise_error(TestBudget::Error, /not found/)
  end

  it "raises Error when results_path is missing" do
    write_budget_file("per_test_case" => {"default" => 5}) do |path|
      expect { described_class.load(path) }.to raise_error(TestBudget::Error, /results_path/)
    end
  end

  it "raises Error when no limits are configured" do
    write_budget_file("results_path" => "tmp/results.json") do |path|
      expect { described_class.load(path) }.to raise_error(TestBudget::Error, /No limits configured/)
    end
  end

  it "does not raise when only suite is configured" do
    write_budget_file("results_path" => "tmp/results.json", "suite" => {"max_duration" => 600}) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "does not raise when only per_test_case default is configured" do
    write_budget_file("results_path" => "tmp/results.json", "per_test_case" => {"default" => 5}) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  it "does not raise when only per_test_case type limits are configured" do
    write_budget_file("results_path" => "tmp/results.json", "per_test_case" => {"model" => 2}) do |path|
      expect { described_class.load(path) }.not_to raise_error
    end
  end

  describe "#add_to_allowlist" do
    def budget_with_results(allowlist: [])
      write_results_file([
        {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid",
         "run_time" => 1.0, "status" => "passed", "line_number" => 4}
      ]) do |rspec_path|
        data = {
          "results_path" => rspec_path,
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
        config = YAML.safe_load_file(budget.path)
        expect(config["allowlist"].size).to eq(1)
        expect(config["allowlist"].first).to eq(
          "test_case" => "spec/models/user_spec.rb -- User is valid",
          "reason" => "Legacy test"
        )
      end
    end

    it "appends to existing allowlist entries" do
      budget_with_results(
        allowlist: [{"test_case" => "spec/models/post_spec.rb -- Post is valid", "reason" => "Slow by design"}]
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
