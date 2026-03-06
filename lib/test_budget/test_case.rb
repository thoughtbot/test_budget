# frozen_string_literal: true

module TestBudget
  class TestCase < Data.define(:file, :name, :duration, :status, :line_number)
    def initialize(file:, name:, duration:, status:, line_number:)
      super(file: file.delete_prefix("./"), name: name, duration: duration, status: status, line_number: line_number)
    end

    def type
      file[%r{^spec/([^/]+)/}, 1]&.chomp("s")&.to_sym || :default
    end

    def key
      "#{file} -- #{name}"
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
