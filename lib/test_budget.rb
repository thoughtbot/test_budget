# frozen_string_literal: true

require_relative "test_budget/version"
require_relative "test_budget/test_case"
require_relative "test_budget/violation"
require_relative "test_budget/budget"
require_relative "test_budget/checks/per_test_case"
require_relative "test_budget/checks/suite"
require_relative "test_budget/auditor"
require_relative "test_budget/reporter"
require_relative "test_budget/parser/rspec"
require_relative "test_budget/audit"
require_relative "test_budget/cli"

module TestBudget
  class Error < StandardError; end

  DEFAULT_BUDGET_PATH = ".test_budget.yml"
end
