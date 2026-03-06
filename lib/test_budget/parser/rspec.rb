# frozen_string_literal: true

require "json"

module TestBudget
  module Parser
    module Rspec
      def self.parse(json_path)
        data = parse_json(json_path)

        data["examples"].map do |example|
          TestCase.new(
            file: example["file_path"],
            name: example["full_description"],
            duration: example["run_time"],
            status: example["status"]
          )
        end
      end

      private_class_method def self.parse_json(path)
        JSON.parse(File.read(path))
      rescue Errno::ENOENT
        raise TestBudget::Error, "RSpec output not found: #{path}"
      rescue JSON::ParserError => e
        raise TestBudget::Error, "Invalid JSON in #{path}: #{e.message}"
      end
    end
  end
end
