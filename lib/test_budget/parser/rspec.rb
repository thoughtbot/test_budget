# frozen_string_literal: true

require "json"

module TestBudget
  module Parser
    module Rspec
      extend self

      def parse(pattern)
        paths = Dir.glob(pattern)
        raise TestBudget::Error, "No timing files found matching: #{pattern}" if paths.empty?

        groups = paths.flat_map { |path| parse_file(path) }
        TestRun.new(
          test_cases: groups.flatten,
          suite_duration: groups.map { |g| g.sum(&:duration) }.max || 0
        )
      end

      private

      def parse_file(path)
        read_json_objects(path).map do |data|
          data["examples"].map do |example|
            TestCase.new(
              file: example["file_path"],
              name: example["full_description"],
              duration: example["run_time"],
              status: example["status"],
              line_number: example["line_number"]
            )
          end
        end
      end

      def read_json_objects(path)
        content = File.read(path)
        [JSON.parse(content)]
      rescue JSON::ParserError
        parse_concatenated_json(content, path)
      end

      CONCATENATED_JSON_BOUNDARY = /(?<=\})(?=\{)/

      def parse_concatenated_json(content, path)
        content.split(CONCATENATED_JSON_BOUNDARY).map { |chunk| JSON.parse(chunk) }
      rescue JSON::ParserError => e
        raise TestBudget::Error, "Invalid JSON in #{path}: #{e.message}"
      end
    end
  end
end
