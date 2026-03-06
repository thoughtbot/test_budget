# frozen_string_literal: true

module TestBudget
  class TestCase < Data.define(:file, :name, :duration, :status)
    def initialize(file:, name:, duration:, status:)
      super(file: file.delete_prefix("./"), name: name, duration: duration, status: status)
    end

    def type
      file[%r{^spec/([^/]+)/}, 1]&.chomp("s")&.to_sym || :default
    end

    def key
      "#{file} -- #{name}"
    end
  end
end
