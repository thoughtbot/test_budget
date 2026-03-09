# frozen_string_literal: true

require "tempfile"
require "yaml"
require "json"

module FileHelpers
  def write_budget_file(data, &block)
    with_tempfile([".test_budget", ".yml"], data.to_yaml, &block)
  end

  def write_timings_file(examples, &block)
    with_tempfile(["test_timings", ".json"], JSON.generate("examples" => examples), &block)
  end

  private

  def with_tempfile(name, content)
    file = Tempfile.create(name)
    file.write(content)
    file.flush
    yield file.path
  ensure
    file&.close
    File.unlink(file.path) if file
  end
end
