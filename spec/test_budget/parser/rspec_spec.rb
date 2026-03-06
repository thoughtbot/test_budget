# frozen_string_literal: true

RSpec.describe TestBudget::Parser::Rspec do
  let(:fixture_path) { File.expand_path("../../fixtures/rspec_output.json", __dir__) }

  it "parses RSpec JSON output into TestCase objects" do
    test_cases = described_class.parse(fixture_path)

    expect(test_cases.size).to eq(3)
    expect(test_cases).to all(be_a(TestBudget::TestCase))
  end

  it "maps fields correctly" do
    test_cases = described_class.parse(fixture_path)
    first = test_cases.first

    expect(first.file).to eq("spec/models/user_spec.rb")
    expect(first.name).to eq("User is valid")
    expect(first.duration).to eq(0.123)
    expect(first.status).to eq("passed")
    expect(first.line_number).to eq(4)
  end

  it "strips ./ from file paths" do
    test_cases = described_class.parse(fixture_path)
    test_cases.each { |tc| expect(tc.file).not_to start_with("./") }
  end

  it "raises Error for missing file" do
    expect { described_class.parse("nonexistent.json") }.to raise_error(TestBudget::Error, /not found/)
  end

  it "raises Error for invalid JSON" do
    file = Tempfile.new(["bad", ".json"])
    file.write("not json")
    file.close

    expect { described_class.parse(file.path) }.to raise_error(TestBudget::Error, /Invalid JSON/)
  end

  it "handles empty examples array" do
    file = Tempfile.new(["empty", ".json"])
    file.write('{"examples": []}')
    file.close

    expect(described_class.parse(file.path)).to eq([])
  end
end
