# frozen_string_literal: true

require "pathname"

# Set up the module/class hierarchy to avoid confusion before requiring all the
# individual node types
module SearchParser::Node
end

require_relative "node/fielded"
require_relative "node/generic"
require_relative "node/multiclause"
require_relative "node/not"
require_relative "node/and"
require_relative "node/or"
require_relative "node/phrase"
require_relative "node/search"
require_relative "node/term"
require_relative "node/tokens"
require_relative "node/empty"
