# frozen_string_literal: true

RSpec.describe TestBudget::Budget::Estimate do
  let(:output) { StringIO.new }

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "#generate" do
    context "with a results file" do
      it "generates config with correct YAML structure" do
        write_timings_file([
          {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid", "run_time" => 1.0, "status" => "passed", "line_number" => 4},
          {"file_path" => "spec/models/post_spec.rb", "full_description" => "Post is valid", "run_time" => 2.0, "status" => "passed", "line_number" => 5},
          {"file_path" => "spec/system/login_spec.rb", "full_description" => "Login works", "run_time" => 4.0, "status" => "passed", "line_number" => 3},
          {"file_path" => "spec/requests/api_spec.rb", "full_description" => "API responds", "run_time" => 1.5, "status" => "passed", "line_number" => 2}
        ]) do |timings_path|
          described_class.new(timings_path: timings_path, output: output).generate

          config = YAML.safe_load_file(".test_budget.yml")
          expect(config["timings_path"]).to eq(timings_path)
          expect(config["suite"]["max_duration"]).to be_a(Integer)
          expect(config["per_test_case"]).to include("default", "model", "system", "request")
          expect(config["allowlist"]).to be_nil
        end
      end

      it "calculates suite budget as ceil(sum * 1.1)" do
        write_timings_file([
          {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid", "run_time" => 5.0, "status" => "passed", "line_number" => 4},
          {"file_path" => "spec/models/post_spec.rb", "full_description" => "Post is valid", "run_time" => 5.0, "status" => "passed", "line_number" => 5}
        ]) do |timings_path|
          described_class.new(timings_path: timings_path, output: output).generate

          config = YAML.safe_load_file(".test_budget.yml")
          expect(config["suite"]["max_duration"]).to eq(11) # ceil(10.0 * 1.1) = 11
        end
      end

      it "derives per-test-case budgets from p95 with buffer" do
        model_durations = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0,
          2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3.0]
        examples = model_durations.each_with_index.map do |d, i|
          {"file_path" => "spec/models/thing#{i}_spec.rb", "full_description" => "Thing#{i}", "run_time" => d, "status" => "passed", "line_number" => 1}
        end

        write_timings_file(examples) do |timings_path|
          described_class.new(timings_path: timings_path, output: output).generate

          config = YAML.safe_load_file(".test_budget.yml")
          # p95 of 1.0..3.0 (21 items): index 19.0, value 2.9
          # with 10% buffer: 2.9 * 1.1 = 3.19, ceil to 1 decimal = 3.2
          expect(config["per_test_case"]["model"]).to eq(3.2)
        end
      end

      it "falls back to defaults for types with no data" do
        write_timings_file([
          {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid", "run_time" => 1.0, "status" => "passed", "line_number" => 4}
        ]) do |timings_path|
          described_class.new(timings_path: timings_path, output: output).generate

          config = YAML.safe_load_file(".test_budget.yml")
          expect(config["per_test_case"]["system"]).to eq(6)
          expect(config["per_test_case"]["request"]).to eq(3)
        end
      end

      it "prints created message" do
        write_timings_file([
          {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid", "run_time" => 1.0, "status" => "passed", "line_number" => 4}
        ]) do |timings_path|
          described_class.new(timings_path: timings_path, output: output).generate

          expect(output.string).to include("Created .test_budget.yml")
        end
      end
    end

    context "without a results file" do
      it "generates config with defaults only and no suite section" do
        described_class.new(timings_path: nil, output: output).generate

        config = YAML.safe_load_file(".test_budget.yml")
        expect(config["timings_path"]).to eq("tmp/test_timings.json")
        expect(config).not_to have_key("suite")
        expect(config["per_test_case"]["default"]).to eq(3)
        expect(config["per_test_case"]["system"]).to eq(6)
        expect(config["per_test_case"]["request"]).to eq(3)
        expect(config["per_test_case"]["model"]).to eq(1.5)
        expect(config["allowlist"]).to be_nil
      end

      it "prints created message" do
        described_class.new(timings_path: nil, output: output).generate

        expect(output.string).to include("Created .test_budget.yml")
      end
    end

    context "when .test_budget.yml already exists" do
      it "raises error suggesting --force" do
        File.write(".test_budget.yml", "existing: config")

        expect {
          described_class.new(timings_path: nil, output: output).generate
        }.to raise_error(TestBudget::Error, /--force/)
      end

      it "overwrites with force: true" do
        File.write(".test_budget.yml", "existing: config")

        described_class.new(timings_path: nil, output: output, force: true).generate

        config = YAML.safe_load_file(".test_budget.yml")
        expect(config["per_test_case"]["default"]).to eq(3)
      end
    end

    it "raises error when explicit results path doesn't exist" do
      expect {
        described_class.new(timings_path: "nonexistent.json", output: output).generate
      }.to raise_error(TestBudget::Error, /No timing files found/)
    end

    it "propagates parser errors for invalid files" do
      Tempfile.create(["bad", ".json"]) do |f|
        f.write("not json")
        f.flush

        expect {
          described_class.new(timings_path: f.path, output: output).generate
        }.to raise_error(TestBudget::Error, /Invalid JSON/)
      end
    end
  end
end
