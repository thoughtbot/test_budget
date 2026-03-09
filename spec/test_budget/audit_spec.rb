# frozen_string_literal: true

RSpec.describe TestBudget::Audit do
  it "returns no violations when all tests are within budget" do
    write_timings_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 1.0, "status" => "passed"
      }
    ]) do |timings_path|
      write_budget_file(
        "timings_path" => timings_path,
        "per_test_case" => {"default" => 5}
      ) do |budget_path|
        audit = described_class.new(budget_path: budget_path)

        result = nil
        expect { result = audit.perform }.to output(/all clear/).to_stdout

        expect(result).to be_passed
      end
    end
  end

  it "returns violations when tests exceed budget" do
    write_timings_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 10.0, "status" => "passed"
      }
    ]) do |timings_path|
      write_budget_file(
        "timings_path" => timings_path,
        "per_test_case" => {"default" => 5}
      ) do |budget_path|
        audit = described_class.new(budget_path: budget_path)

        result = nil
        expect { result = audit.perform }.to output(/violation/).to_stdout

        expect(result).not_to be_passed
      end
    end
  end
end
