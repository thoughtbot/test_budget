# frozen_string_literal: true

RSpec.describe TestBudget::CLI do
  let(:cli) { described_class.new }

  it "returns 0 when all tests are within budget" do
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
        exit_code = nil
        expect { exit_code = cli.call(["audit", "--budget", budget_path]) }
          .to output(/all clear/).to_stdout

        expect(exit_code).to eq(0)
      end
    end
  end

  it "returns 1 when tests exceed budget" do
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
        exit_code = nil
        expect { exit_code = cli.call(["audit", "--budget", budget_path]) }
          .to output(/violation/).to_stdout

        expect(exit_code).to eq(1)
      end
    end
  end

  describe "help" do
    it "prints help and returns 0 for 'help' command" do
      exit_code = nil
      expect { exit_code = cli.call(["help"]) }
        .to output(/Usage: test_budget <command>.*audit.*allowlist.*init/m).to_stdout

      expect(exit_code).to eq(0)
    end

    it "prints help and returns 0 for --help flag" do
      exit_code = nil
      expect { exit_code = cli.call(["--help"]) }
        .to output(/Usage: test_budget <command>/).to_stdout

      expect(exit_code).to eq(0)
    end

    it "prints help and returns 0 for -h flag" do
      exit_code = nil
      expect { exit_code = cli.call(["-h"]) }
        .to output(/Usage: test_budget <command>/).to_stdout

      expect(exit_code).to eq(0)
    end

    it "prints help and returns 0 with no arguments" do
      exit_code = nil
      expect { exit_code = cli.call([]) }
        .to output(/Usage: test_budget <command>/).to_stdout

      expect(exit_code).to eq(0)
    end
  end

  describe "version" do
    it "prints version and returns 0 for --version" do
      exit_code = nil
      expect { exit_code = cli.call(["--version"]) }
        .to output(include(TestBudget::VERSION)).to_stdout

      expect(exit_code).to eq(0)
    end

    it "prints version and returns 0 for -v" do
      exit_code = nil
      expect { exit_code = cli.call(["-v"]) }
        .to output(include(TestBudget::VERSION)).to_stdout

      expect(exit_code).to eq(0)
    end
  end

  it "returns 1 for unknown command" do
    exit_code = nil
    expect { exit_code = cli.call(["unknown"]) }
      .to output(/invalid argument/).to_stderr

    expect(exit_code).to eq(1)
  end

  it "reports errors to stderr and returns 1" do
    exit_code = nil
    expect { exit_code = cli.call(["audit", "--budget", "nonexistent.yml"]) }
      .to output(/not found/).to_stderr

    expect(exit_code).to eq(1)
  end

  describe "allowlist subcommand" do
    it "writes entry and returns 0" do
      write_timings_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |timings_path|
        write_budget_file(
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5}
        ) do |budget_path|
          exit_code = nil
          expect { exit_code = cli.call(["allowlist", "spec/models/user_spec.rb:4", "--reason", "Legacy test", "--budget", budget_path]) }
            .to output(/Allowlisted/).to_stdout

          expect(exit_code).to eq(0)
          config = YAML.safe_load_file(budget_path)
          expect(config["allowlist"].first["test_case"]).to eq("spec/models/user_spec.rb -- User is valid")
          expect(config["allowlist"].first["reason"]).to eq("Legacy test")
          expect(config["allowlist"].first["expires_on"]).to eq((Date.today + TestBudget::Budget::DEFAULT_EXPIRATION_DAYS).to_s)
        end
      end
    end

    it "returns 1 when --reason is missing" do
      write_timings_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |timings_path|
        write_budget_file(
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5}
        ) do |budget_path|
          exit_code = nil
          expect { exit_code = cli.call(["allowlist", "spec/models/user_spec.rb:4", "--budget", budget_path]) }
            .to output(/--reason is required/).to_stderr

          expect(exit_code).to eq(1)
        end
      end
    end

    it "handles missing option arguments" do
      exit_code = nil
      expect { exit_code = cli.call(["allowlist", "spec/models/user_spec.rb:4", "--reason"]) }
        .to output(/missing argument/).to_stderr

      expect(exit_code).to eq(1)
    end

    it "returns 1 when no matching test case" do
      write_timings_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |timings_path|
        write_budget_file(
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5}
        ) do |budget_path|
          exit_code = nil
          expect { exit_code = cli.call(["allowlist", "spec/models/post_spec.rb:4", "--reason", "test", "--budget", budget_path]) }
            .to output(/No test case found/).to_stderr

          expect(exit_code).to eq(1)
        end
      end
    end
  end

  describe "prune subcommand" do
    it "prints count and returns 0 when entries removed" do
      write_timings_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 1.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |timings_path|
        write_budget_file(
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5},
          "allowlist" => [
            {"test_case" => "spec/models/old_spec.rb -- gone test", "reason" => "Stale", "expires_on" => (Date.today + 365).to_s}
          ]
        ) do |budget_path|
          exit_code = nil
          expect { exit_code = cli.call(["prune", "--budget", budget_path]) }
            .to output(/1 obsolete allowlist entry removed/).to_stdout

          expect(exit_code).to eq(0)
        end
      end
    end

    it "prints 'no obsolete' and returns 0 when nothing to prune" do
      write_timings_file([
        {
          "file_path" => "spec/models/user_spec.rb",
          "full_description" => "User is valid",
          "run_time" => 10.0, "status" => "passed",
          "line_number" => 4
        }
      ]) do |timings_path|
        write_budget_file(
          "timings_path" => timings_path,
          "per_test_case" => {"default" => 5},
          "allowlist" => [
            {"test_case" => "spec/models/user_spec.rb -- User is valid", "reason" => "Still slow", "expires_on" => (Date.today + 365).to_s}
          ]
        ) do |budget_path|
          exit_code = nil
          expect { exit_code = cli.call(["prune", "--budget", budget_path]) }
            .to output(/No obsolete allowlist entries found/).to_stdout

          expect(exit_code).to eq(0)
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
      write_timings_file([
        {"file_path" => "spec/models/user_spec.rb", "full_description" => "User is valid", "run_time" => 1.0, "status" => "passed", "line_number" => 4}
      ]) do |timings_path|
        exit_code = nil
        expect { exit_code = cli.call(["init", timings_path]) }
          .to output(/Created/).to_stdout

        expect(exit_code).to eq(0)
        config = YAML.safe_load_file(".test_budget.yml")
        expect(config["timings_path"]).to eq(timings_path)
        expect(config["suite"]["max_duration"]).to be_a(Integer)
      end
    end

    it "uses no-input mode when default path doesn't exist" do
      exit_code = nil
      expect { exit_code = cli.call(["init"]) }
        .to output(/Created/).to_stdout

      expect(exit_code).to eq(0)
      config = YAML.safe_load_file(".test_budget.yml")
      expect(config["timings_path"]).to eq("tmp/test_timings.json")
      expect(config).not_to have_key("suite")
    end

    it "passes --force flag" do
      File.write(".test_budget.yml", "existing: config")

      exit_code = nil
      expect { exit_code = cli.call(["init", "--force"]) }
        .to output(/Created/).to_stdout

      expect(exit_code).to eq(0)
      config = YAML.safe_load_file(".test_budget.yml")
      expect(config["per_test_case"]["default"]).to eq(3)
    end

    it "returns 1 when explicit results file doesn't exist" do
      exit_code = nil
      expect { exit_code = cli.call(["init", "nonexistent.json"]) }
        .to output(/No timing files found/).to_stderr

      expect(exit_code).to eq(1)
    end

    it "returns 1 when config exists without --force" do
      File.write(".test_budget.yml", "existing: config")

      exit_code = nil
      expect { exit_code = cli.call(["init"]) }
        .to output(/--force/).to_stderr

      expect(exit_code).to eq(1)
    end
  end
end
