# frozen_string_literal: true

RSpec.describe TestBudget::Audit do
  let(:output) { StringIO.new }

  it "returns no violations when all tests are within budget" do
    results_path = write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 1.0, "status" => "passed"
      }
    ])
    budget_path = write_budget_file(
      "results_path" => results_path,
      "per_test_case" => {"default" => 5}
    )

    audit = described_class.new(budget_path: budget_path, output: output)
    result = audit.perform

    expect(result).to eq(true)
    expect(output.string).to include("all clear")
  end

  it "returns violations when tests exceed budget" do
    results_path = write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 10.0, "status" => "passed"
      }
    ])
    budget_path = write_budget_file(
      "results_path" => results_path,
      "per_test_case" => {"default" => 5}
    )

    audit = described_class.new(budget_path: budget_path, output: output)
    result = audit.perform

    expect(result).to eq(false)
    expect(output.string).to include("violation")
  end
end
