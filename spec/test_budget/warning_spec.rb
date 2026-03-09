# frozen_string_literal: true

RSpec.describe TestBudget::Warning do
  def make_entry(test_case_key: "spec/models/user_spec.rb -- User is valid", reason: "legacy test")
    TestBudget::Allowlist::Entry.new(test_case_key: test_case_key, reason: reason)
  end

  it "formats stale warning with reason" do
    warning = described_class.new(entry: make_entry, kind: :stale)

    expect(warning.message).to eq(
      "obsolete allowlist entry (stale)\nspec/models/user_spec.rb -- User is valid\nreason: legacy test"
    )
  end

  it "formats unnecessary warning" do
    warning = described_class.new(entry: make_entry, kind: :unnecessary)

    expect(warning.message).to include("unnecessary")
    expect(warning.message).to include("spec/models/user_spec.rb -- User is valid")
  end

  it "handles nil reason" do
    warning = described_class.new(entry: make_entry(reason: nil), kind: :stale)

    expect(warning.message).not_to include("reason:")
  end
end
