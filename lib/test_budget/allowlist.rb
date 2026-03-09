# frozen_string_literal: true

require "date"

module TestBudget
  class Allowlist
    def initialize(raw_entries = [])
      @entries = raw_entries.map do |entry|
        Entry.new(
          test_case_key: entry["test_case"],
          reason: entry["reason"],
          expires_on: parse_date(entry["expires_on"])
        )
      end
    end

    def allowed?(key)
      @entries.find { |e| e.matches?(key) }
    end

    def add(key, reason:, expires_on:)
      raise Error, "#{key} is already allowlisted" if allowed?(key)

      entry = Entry.new(test_case_key: key, reason: reason, expires_on: expires_on)
      @entries << entry
      entry
    end

    def prune(test_run, budget)
      removed, @entries = @entries.partition { |entry| entry.obsolete?(test_run, budget) }
      removed
    end

    def to_a
      @entries.dup
    end

    private

    def parse_date(raw)
      Date.parse(raw.to_s)
    rescue Date::Error, TypeError
      raise Error, "expires_on is required and must be a valid date (YYYY-MM-DD)"
    end

    Entry = Data.define(:test_case_key, :reason, :expires_on) do
      def expired? = Date.today > expires_on

      def matches?(key)
        test_case_key == key
      end

      def obsolete?(test_run, budget)
        test_case = test_run.test_cases.find { |tc| tc.key == test_case_key }

        if test_case.nil?
          :stale
        elsif test_case.within?(budget)
          :unnecessary
        end
      end

      def to_h
        {"test_case" => test_case_key, "reason" => reason, "expires_on" => expires_on.to_s}
      end
    end
  end
end
