# frozen_string_literal: true

module TestBudget
  class Allowlist
    def initialize(raw_entries = [])
      @entries = raw_entries.map do |entry|
        Entry.new(test_case_key: entry["test_case"], reason: entry["reason"])
      end
    end

    def allowed?(key)
      @entries.any? { |e| e.matches?(key) }
    end

    def add(key, reason:)
      raise Error, "#{key} is already allowlisted" if allowed?(key)

      entry = Entry.new(test_case_key: key, reason: reason)
      @entries << entry
      entry
    end

    def to_a
      @entries.dup
    end

    Entry = Data.define(:test_case_key, :reason) do
      def matches?(key)
        test_case_key == key
      end

      def to_h
        {"test_case" => test_case_key, "reason" => reason}
      end
    end
  end
end
