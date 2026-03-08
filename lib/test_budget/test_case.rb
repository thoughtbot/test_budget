# frozen_string_literal: true

module TestBudget
  class TestCase < Data.define(:file, :name, :duration, :status, :line_number)
    def initialize(file:, name:, duration:, status:, line_number:)
      super(file: file.delete_prefix("./"), name: name, duration: duration, status: status, line_number: line_number)
    end

    IRREGULAR_TYPES = {
      "policies" => :policy,
      "factories" => :factory,
      "queries" => :query
    }.freeze

    def type
      dir = file[%r{^spec/([^/]+)/}, 1]
      return :default unless dir

      IRREGULAR_TYPES[dir] || dir.chomp("s").to_sym
    end

    def key
      "#{file} -- #{name}"
    end

    def over?(budget)
      return if budget.allowed?(self)

      limit = budget.limit_for(self)
      return unless limit
      return if duration <= limit

      Violation.new(test_case: self, duration: duration, limit: limit, kind: :per_test_case)
    end

    def self.find_by_location!(test_cases, locator)
      file, line = parse_locator(locator)
      match = test_cases.find { |tc| tc.file == file && tc.line_number == line }

      raise Error, "No test case found at #{locator}" unless match

      match
    end

    def self.parse_locator(locator)
      m = locator.match(/\A(.+):(\d+)\z/)
      raise Error, "Line number required in locator (e.g., spec/file_spec.rb:10)" unless m

      [m[1], m[2].to_i]
    end

    private_class_method :parse_locator
  end
end
