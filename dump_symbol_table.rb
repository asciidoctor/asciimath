require_relative 'lib/asciimath'

puts "|==="
puts '|Asciimath |Symbol |Codepoint |Value'
puts

AsciiMath::Parser::SYMBOLS.each_pair do |asciimath, value|
  sym = value[:value]
  unless sym.is_a?(Symbol)
    next
  end

  mathml = AsciiMath::MathMLBuilder::SYMBOLS[sym]

  if mathml
    val = mathml[:value]
  else
    val = "Missing!!!!!"
  end

  codepoint = ""
  if val.is_a?(String)
    codepoint = val.codepoints.map { |cp| sprintf('U+%04X', cp) }.join(' ')
  end
  puts "|#{asciimath} |:#{sym.to_s} |#{codepoint} |#{val}"
end

puts "|==="
puts