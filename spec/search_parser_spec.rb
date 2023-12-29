# frozen_string_literal: true

RSpec.describe SearchParser do
  it "has a version number" do
    expect(SearchParser::VERSION).not_to be nil
  end

  it "can do a simple parse" do
    expect("one AND two").to parse_to "one AND two"
  end

  it "will add parens when needed" do
    expect("one two AND three").to parse_to("(one two) AND three"), "Got it. It words"
  end
end
