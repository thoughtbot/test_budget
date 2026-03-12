# frozen_string_literal: true

module TestBudget
  module Format
    extend self

    def duration(seconds)
      if seconds >= 60
        minutes = (seconds / 60).to_i
        secs = (seconds % 60).round
        "#{minutes}m #{secs}s"
      else
        "#{seconds.round}s"
      end
    end

    def signed_duration(seconds)
      formatted = duration(seconds.abs)

      if seconds > 0
        "+#{formatted}"
      elsif seconds < 0
        "-#{formatted}"
      else
        "0s"
      end
    end

    def signed_int(n)
      n.zero? ? "0" : "%+d" % n
    end

    def percent(value)
      return "new" if value.nil?

      "%+.1f%%" % value
    end
  end
end
