# frozen_string_literal: true

RSpec.describe TestBudget::TestCase do
  describe "#type" do
    {
      "spec/system/login_spec.rb" => :system,
      "spec/requests/api_spec.rb" => :request,
      "spec/models/user_spec.rb" => :model,
      "spec/controllers/users_controller_spec.rb" => :controller,
      "spec/helpers/application_helper_spec.rb" => :helper,
      "spec/views/users/index_spec.rb" => :view,
      "spec/mailers/user_mailer_spec.rb" => :mailer,
      "spec/jobs/cleanup_job_spec.rb" => :job,
      "spec/features/sign_in_spec.rb" => :feature,
      "spec/policies/admin_policy_spec.rb" => :policy,
      "spec/queries/user_query_spec.rb" => :query,
      "spec/factories/user_factory_spec.rb" => :factory
    }.each do |file, expected_type|
      it "returns #{expected_type.inspect} for #{file}" do
        test_case = described_class.new(file: file, name: "example", duration: 1.0, status: "passed", line_number: 1)
        expect(test_case.type).to eq(expected_type)
      end
    end

    it "infers type from any spec subdirectory" do
      test_case = described_class.new(file: "spec/lib/utils_spec.rb", name: "example", duration: 1.0, status: "passed", line_number: 1)
      expect(test_case.type).to eq(:lib)
    end

    it "returns :default for files not under spec/" do
      test_case = described_class.new(file: "test/something_test.rb", name: "example", duration: 1.0, status: "passed", line_number: 1)
      expect(test_case.type).to eq(:default)
    end
  end

  describe "#key" do
    it "returns file and name joined by --" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "User#full_name",
        duration: 1.0, status: "passed", line_number: 1
      )
      expect(test_case.key).to eq("spec/models/user_spec.rb -- User#full_name")
    end
  end

  describe "#line_number" do
    it "stores line_number" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "example",
        duration: 1.0, status: "passed", line_number: 4
      )
      expect(test_case.line_number).to eq(4)
    end
  end

  describe "#over?" do
    let(:budget) { build_budget(per_test_case: {default: 5, types: {model: 2}}) }

    it "returns nil when under budget" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "example",
        duration: 1.5, status: "passed", line_number: 1
      )
      expect(test_case.over?(budget)).to be_nil
    end

    it "returns violation when over budget" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "example",
        duration: 2.5, status: "passed", line_number: 1
      )
      violation = test_case.over?(budget)

      expect(violation).to be_a(TestBudget::Violation)
      expect(violation.kind).to eq(:per_test_case)
      expect(violation.limit).to eq(2)
      expect(violation.duration).to eq(2.5)
    end

    it "returns nil when exactly at budget" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "example",
        duration: 2.0, status: "passed", line_number: 1
      )
      expect(test_case.over?(budget)).to be_nil
    end

    it "uses type-specific limit when available" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "example",
        duration: 3.0, status: "passed", line_number: 1
      )
      violation = test_case.over?(budget)
      expect(violation.limit).to eq(2)
    end

    it "falls back to default limit for unknown types" do
      test_case = described_class.new(
        file: "spec/lib/utils_spec.rb", name: "example",
        duration: 6.0, status: "passed", line_number: 1
      )
      violation = test_case.over?(budget)
      expect(violation.limit).to eq(5)
    end

    it "returns nil when allowlisted" do
      budget = build_budget(
        per_test_case: {default: 2},
        allowlist: ["spec/models/user_spec.rb -- example"]
      )
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "example",
        duration: 3.0, status: "passed", line_number: 1
      )
      expect(test_case.over?(budget)).to be_nil
    end
  end

  describe ".find_by_location!" do
    let(:test_cases) do
      [
        described_class.new(file: "spec/models/user_spec.rb", name: "User is valid", duration: 1.0, status: "passed", line_number: 4),
        described_class.new(file: "spec/models/user_spec.rb", name: "User has name", duration: 1.0, status: "passed", line_number: 10)
      ]
    end

    it "finds test case by exact file and line" do
      result = described_class.find_by_location!(test_cases, "spec/models/user_spec.rb:4")

      expect(result.name).to eq("User is valid")
    end

    it "raises Error when no exact match" do
      expect {
        described_class.find_by_location!(test_cases, "spec/models/user_spec.rb:6")
      }.to raise_error(TestBudget::Error, /No test case found at/)
    end

    it "raises Error when locator has no line number" do
      expect {
        described_class.find_by_location!(test_cases, "spec/models/user_spec.rb")
      }.to raise_error(TestBudget::Error, /line number required/i)
    end
  end

  describe "file normalization" do
    it "strips leading ./ from file" do
      test_case = described_class.new(
        file: "./spec/models/user_spec.rb", name: "example",
        duration: 1.0, status: "passed", line_number: 1
      )
      expect(test_case.file).to eq("spec/models/user_spec.rb")
    end
  end
end
