require "pathname"
(Pathname.new(__dir__) + "node").each_entry do |nodefile|
  puts "node/" + nodefile.basename(".rb").to_s
end
