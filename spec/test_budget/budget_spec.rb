# frozen_string_literal: true

RSpec.describe TestBudget::Budget do
  it "loads configuration from YAML" do
    path = write_budget_file(
      "results_path" => "tmp/results.json",
      "suite" => {"max_duration" => 600},
      "per_test_case" => {"default" => 3, "by_type" => {"system" => 10, "model" => 2}},
      "allowlist" => ["spec/models/user_spec.rb -- User#slow"]
    )

    budget = described_class.load(path)

    expect(budget.results_path).to eq("tmp/results.json")
    expect(budget.suite.max_duration).to eq(600)
    expect(budget.per_test_case.default).to eq(3)
    expect(budget.per_test_case.by_type).to eq({system: 10, model: 2})
    slow_test = TestBudget::TestCase.new(file: "spec/models/user_spec.rb", name: "User#slow", duration: 1.0, status: "passed")
    expect(budget.allowed?(slow_test)).to be true
  end

  it "converts by_type keys to symbols" do
    path = write_budget_file(
      "results_path" => "tmp/results.json",
      "per_test_case" => {"by_type" => {"request" => 3}}
    )

    budget = described_class.load(path)

    expect(budget.per_test_case.by_type).to eq({request: 3})
  end

  it "raises Error for missing file" do
    expect { described_class.load("nonexistent.yml") }.to raise_error(TestBudget::Error, /not found/)
  end

  it "raises Error when results_path is missing" do
    path = write_budget_file("per_test_case" => {"default" => 5})

    expect { described_class.load(path) }.to raise_error(TestBudget::Error, /results_path/)
  end

  it "raises Error when no limits are configured" do
    path = write_budget_file("results_path" => "tmp/results.json")

    expect { described_class.load(path) }.to raise_error(TestBudget::Error, /No limits configured/)
  end

  it "does not raise when only suite is configured" do
    path = write_budget_file("results_path" => "tmp/results.json", "suite" => {"max_duration" => 600})

    expect { described_class.load(path) }.not_to raise_error
  end

  it "does not raise when only per_test_case default is configured" do
    path = write_budget_file("results_path" => "tmp/results.json", "per_test_case" => {"default" => 5})

    expect { described_class.load(path) }.not_to raise_error
  end

  it "does not raise when only per_test_case by_type is configured" do
    path = write_budget_file("results_path" => "tmp/results.json", "per_test_case" => {"by_type" => {"model" => 2}})

    expect { described_class.load(path) }.not_to raise_error
  end
end
