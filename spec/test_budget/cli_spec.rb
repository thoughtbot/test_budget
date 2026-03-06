# frozen_string_literal: true

RSpec.describe TestBudget::CLI do
  let(:output) { StringIO.new }
  let(:error) { StringIO.new }
  let(:cli) { described_class.new(output: output, error: error) }

  it "returns 0 when all tests are within budget" do
    write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 1.0, "status" => "passed"
      }
    ]) do |rspec_path|
      write_budget_file(
        "results_path" => rspec_path,
        "per_test_case" => {"default" => 5}
      ) do |budget_path|
        exit_code = cli.call(["audit", "--budget", budget_path])

        expect(exit_code).to eq(0)
        expect(output.string).to include("all clear")
      end
    end
  end

  it "returns 1 when tests exceed budget" do
    write_results_file([
      {
        "file_path" => "spec/models/user_spec.rb",
        "full_description" => "User is valid",
        "run_time" => 10.0, "status" => "passed"
      }
    ]) do |rspec_path|
      write_budget_file(
        "results_path" => rspec_path,
        "per_test_case" => {"default" => 5}
      ) do |budget_path|
        exit_code = cli.call(["audit", "--budget", budget_path])

        expect(exit_code).to eq(1)
        expect(output.string).to include("violation")
      end
    end
  end

  it "returns 1 for unknown command" do
    exit_code = cli.call(["unknown"])

    expect(exit_code).to eq(1)
    expect(error.string).to include("invalid argument")
  end

  it "reports errors to stderr and returns 1" do
    exit_code = cli.call(["audit", "--budget", "nonexistent.yml"])

    expect(exit_code).to eq(1)
    expect(error.string).to include("not found")
  end

  describe "allowlist subcommand" do
    it "writes entry and returns 0" do
      write_results_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |rspec_path|
        write_budget_file(
          "results_path" => rspec_path,
          "per_test_case" => {"default" => 5}
        ) do |budget_path|
          exit_code = cli.call(["allowlist", "spec/models/user_spec.rb:4", "--reason", "Legacy test", "--budget", budget_path])

          expect(exit_code).to eq(0)
          config = YAML.safe_load_file(budget_path)
          expect(config["allowlist"].first["test_case"]).to eq("spec/models/user_spec.rb -- User is valid")
          expect(config["allowlist"].first["reason"]).to eq("Legacy test")
          expect(output.string).to include("Allowlisted")
        end
      end
    end

    it "returns 1 when --reason is missing" do
      write_results_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |rspec_path|
        write_budget_file(
          "results_path" => rspec_path,
          "per_test_case" => {"default" => 5}
        ) do |budget_path|
          exit_code = cli.call(["allowlist", "spec/models/user_spec.rb:4", "--budget", budget_path])

          expect(exit_code).to eq(1)
          expect(error.string).to include("--reason is required")
        end
      end
    end

    it "handles missing option arguments" do
      exit_code = cli.call(["allowlist", "spec/models/user_spec.rb:4", "--reason"])

      expect(exit_code).to eq(1)
      expect(error.string).to include("missing argument")
    end

    it "returns 1 when no matching test case" do
      write_results_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |rspec_path|
        write_budget_file(
          "results_path" => rspec_path,
          "per_test_case" => {"default" => 5}
        ) do |budget_path|
          exit_code = cli.call(["allowlist", "spec/models/post_spec.rb:4", "--reason", "test", "--budget", budget_path])

          expect(exit_code).to eq(1)
          expect(error.string).to include("No test case found")
        end
      end
    end
  end

  describe "init subcommand" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { example.run }
      end
    end

    it "generates config from custom results path" do
      write_results_file([
        {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid", "run_time" => 1.0, "status" => "passed", "line_number" => 4}
      ]) do |rspec_path|
        exit_code = cli.call(["init", rspec_path])

        expect(exit_code).to eq(0)
        config = YAML.safe_load_file(".test_budget.yml")
        expect(config["results_path"]).to eq(rspec_path)
        expect(config["suite"]["max_duration"]).to be_a(Integer)
      end
    end

    it "uses no-input mode when default path doesn't exist" do
      exit_code = cli.call(["init"])

      expect(exit_code).to eq(0)
      config = YAML.safe_load_file(".test_budget.yml")
      expect(config["results_path"]).to eq("tmp/test_budget_results.json")
      expect(config).not_to have_key("suite")
    end

    it "passes --force flag" do
      File.write(".test_budget.yml", "existing: config")

      exit_code = cli.call(["init", "--force"])

      expect(exit_code).to eq(0)
      config = YAML.safe_load_file(".test_budget.yml")
      expect(config["per_test_case"]["default"]).to eq(3)
    end

    it "returns 1 when explicit results file doesn't exist" do
      exit_code = cli.call(["init", "nonexistent.json"])

      expect(exit_code).to eq(1)
      expect(error.string).to include("not found")
    end

    it "returns 1 when config exists without --force" do
      File.write(".test_budget.yml", "existing: config")

      exit_code = cli.call(["init"])

      expect(exit_code).to eq(1)
      expect(error.string).to include("--force")
    end
  end
end
