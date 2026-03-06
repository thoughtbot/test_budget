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
      "spec/features/sign_in_spec.rb" => :feature
    }.each do |file, expected_type|
      it "returns #{expected_type.inspect} for #{file}" do
        test_case = described_class.new(file: file, name: "example", duration: 1.0, status: "passed")
        expect(test_case.type).to eq(expected_type)
      end
    end

    it "infers type from any spec subdirectory" do
      test_case = described_class.new(file: "spec/lib/utils_spec.rb", name: "example", duration: 1.0, status: "passed")
      expect(test_case.type).to eq(:lib)
    end

    it "returns :default for files not under spec/" do
      test_case = described_class.new(file: "test/something_test.rb", name: "example", duration: 1.0, status: "passed")
      expect(test_case.type).to eq(:default)
    end
  end

  describe "#key" do
    it "returns file and name joined by --" do
      test_case = described_class.new(
        file: "spec/models/user_spec.rb", name: "User#full_name",
        duration: 1.0, status: "passed"
      )
      expect(test_case.key).to eq("spec/models/user_spec.rb -- User#full_name")
    end
  end

  describe "file normalization" do
    it "strips leading ./ from file" do
      test_case = described_class.new(
        file: "./spec/models/user_spec.rb", name: "example",
        duration: 1.0, status: "passed"
      )
      expect(test_case.file).to eq("spec/models/user_spec.rb")
    end
  end
end
