# frozen_string_literal: true

require "search_parser"
require "csv"

basic_config = SearchParser::Parsing::Config.new(field_names: %w[author title])
P = SearchParser.new(basic_config)

def file_triples(file, &blk)
  File.open(file).each do |line|
    line.chomp!
    line.strip!
    next if line[0] == "#"
    next if line == ""
    given, expected, comment = line.split("|")
    expected = given if expected.nil?
    expected.strip!
    yield given, expected, comment
  end
end

def test_triple(given, expected, comment)
  it given do
    if comment
      expect(given).to parse_to(expected), comment
    else
      expect(given).to parse_to(expected)
    end
  end
end

RSpec::Matchers.define :parse_to do |exp|
  description { "parse to" }
  match do |given|
    @given = given.strip
    @actual = P.parse(given).to_s.strip
    @expected = exp
    # expect(@expected).to eq(@actual)
    @expected == @actual
  end
  failure_message do |given|
    "Expected `#{@given}` to parse to `#{@expected}`, not `#{@actual}`"
  end
  diffable
  attr_reader :actual, :expected
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
