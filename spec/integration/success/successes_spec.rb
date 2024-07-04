# frozen_string_literal: true

RSpec.describe "Successful Parses by string comparison" do
  describe "Simple keywords" do
    file_triples(File.join(__dir__, "successes.tsv")) do |given, expected, comment|
      test_triple(given, expected, comment)
    end
  end
end
