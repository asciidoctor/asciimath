require_relative 'lib/asciimath'

def escape_adoc(adoc)
  case adoc
    when nil
      ''
    when '+'
      adoc
    else
      "++#{adoc.gsub('|', '\\|')}++"
  end
end

puts "|==="
puts '|AsciiMath |Symbol |MathML Value |LaTeX Value'
puts

AsciiMath::Parser::DEFAULT_PARSER_SYMBOL_TABLE.each_pair do |asciimath, value|
  sym = value[:value]
  unless sym.is_a?(Symbol)
    next
  end

  mathml = AsciiMath::MathMLBuilder::DEFAULT_DISPLAY_SYMBOL_TABLE[sym]

  if mathml
    val = mathml[:value]
  else
    val = "Missing!!!!!"
  end

  latex = AsciiMath::LatexBuilder::SYMBOLS[sym] || "\\#{sym.to_s}"

  codepoint = ""
  if val.is_a?(String)
    codepoint = val.codepoints.map do |cp|
      cpstr = sprintf('U+%04X', cp)
      "https://codepoints.net/#{cpstr}[#{cpstr}]"
    end.join(' ')
  end

  puts "|#{escape_adoc(asciimath)} |:#{sym.to_s} |#{escape_adoc(val.to_s)} (#{codepoint}) |#{escape_adoc(latex)}"
end

puts "|==="
puts