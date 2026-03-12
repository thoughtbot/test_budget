# frozen_string_literal: true

module TestBudget
  module Inflector
    IRREGULARS = {
      "entry" => "entries",
      "policy" => "policies",
      "factory" => "factories",
      "query" => "queries"
    }.freeze

    def self.pluralize(word, count)
      count == 1 ? word : (IRREGULARS[word] || "#{word}s")
    end

    def self.singularize(word)
      IRREGULARS.key(word) || word.chomp("s")
    end
  end
end
