# frozen_string_literal: true

module TestBudget
  module Statistics
    def self.p99(values, tolerance: 0) = percentile(0.99, values, tolerance: tolerance)

    private_class_method def self.percentile(rank, values, tolerance: 0)
      sorted = values.sort
      n = sorted.size
      return apply_tolerance(sorted[0], tolerance) if n == 1

      index = rank * (n - 1)
      lower = sorted[index.floor]
      upper = sorted[index.ceil]
      result = lower + (upper - lower) * (index - index.floor)

      apply_tolerance(result, tolerance)
    end

    private_class_method def self.apply_tolerance(value, tolerance)
      ceil_to_half(value * (1 + tolerance))
    end

    private_class_method def self.ceil_to_half(value)
      (value * 2).ceil / 2.0
    end
  end
end
