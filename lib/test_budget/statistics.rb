# frozen_string_literal: true

module TestBudget
  module Statistics
    def self.percentile_95(values, buffer: 0)
      sorted = values.sort
      n = sorted.size
      return apply_buffer(sorted[0], buffer) if n == 1

      index = 0.95 * (n - 1)
      lower = sorted[index.floor]
      upper = sorted[index.ceil]
      p95 = lower + (upper - lower) * (index - index.floor)
      apply_buffer(p95, buffer)
    end

    private_class_method def self.apply_buffer(value, buffer)
      ((value * (1 + buffer)) * 10).ceil / 10.0
    end
  end
end
