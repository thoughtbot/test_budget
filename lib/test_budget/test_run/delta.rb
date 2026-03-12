# frozen_string_literal: true

module TestBudget
  class TestRun
    Delta = Data.define(:label, :before, :after) do
      def count = after.count - before.count
      def duration = after.duration - before.duration

      def new? = before.count == 0
      def removed? = after.count == 0
      def zero? = count == 0 && duration == 0

      def percent_count
        return if new?
        return -100.0 if removed?

        count * 100.0 / before.count
      end

      def percent_duration
        return if new?
        return -100.0 if removed?

        duration * 100.0 / before.duration
      end
    end
  end
end
