# frozen_string_literal: true

RSpec.describe TestBudget::CLI do
  let(:output) { StringIO.new }
  let(:error) { StringIO.new }
  let(:cli) { described_class.new(output: output, error: error) }

  it "returns 0 when all tests are within budget" do
    rspec_path = write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 1.0, "status" => "passed"
      }
    ])
    budget_path = write_budget_file(
      "results_path" => rspec_path,
      "per_test_case" => {"default" => 5}
    )

    exit_code = cli.call(["audit", "--budget", budget_path])

    expect(exit_code).to eq(0)
    expect(output.string).to include("all clear")
  end

  it "returns 1 when tests exceed budget" do
    rspec_path = write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 10.0, "status" => "passed"
      }
    ])
    budget_path = write_budget_file(
      "results_path" => rspec_path,
      "per_test_case" => {"default" => 5}
    )

    exit_code = cli.call(["audit", "--budget", budget_path])

    expect(exit_code).to eq(1)
    expect(output.string).to include("violation")
  end

  it "defaults to audit subcommand" do
    rspec_path = write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 1.0, "status" => "passed"
      }
    ])
    budget_path = write_budget_file("results_path" => rspec_path, "per_test_case" => {"default" => 5})

    exit_code = cli.call(["--budget", budget_path])

    expect(exit_code).to eq(0)
  end

  it "reports errors to stderr and returns 1" do
    exit_code = cli.call(["audit", "--budget", "nonexistent.yml"])

    expect(exit_code).to eq(1)
    expect(error.string).to include("not found")
  end
end
