require_relative 'lib/asciimath'

def escape_adoc(adoc)
  case adoc
    when '+'
      adoc
    else
      "++#{adoc.gsub('|', '\\|')}++"
  end
end

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

  puts "|#{escape_adoc(asciimath)} |:#{sym.to_s} |#{codepoint} |#{escape_adoc(val.to_s)}"
end

puts "|==="
puts