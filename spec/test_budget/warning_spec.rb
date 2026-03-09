# frozen_string_literal: true

RSpec.describe TestBudget::Warning do
  it "formats stale warning with reason" do
    warning = described_class.new(entry: build_entry, kind: :stale)

    expect(warning.message).to eq(
      "obsolete allowlist entry (stale)\nspec/models/user_spec.rb -- User is valid\nreason: legacy test"
    )
  end

  it "formats unnecessary warning" do
    warning = described_class.new(entry: build_entry, kind: :unnecessary)

    expect(warning.message).to include("unnecessary")
    expect(warning.message).to include("spec/models/user_spec.rb -- User is valid")
  end

  it "handles nil reason" do
    warning = described_class.new(entry: build_entry(reason: nil), kind: :stale)

    expect(warning.message).not_to include("reason:")
  end
end
