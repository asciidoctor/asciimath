#encoding: utf-8
require 'rspec'
require 'asciimath'
require_relative 'ast'

RSpec.configure do |c|
  c.include ::AsciiMath::ASTHelper
end

describe 'AsciiMath::Parser', :variant => :ast do
  it "should support custom symbols" do
    my_tokens_table = AsciiMath::SymbolTableBuilder.new
    AsciiMath::Parser.add_default_parser_symbols(my_tokens_table)
    my_tokens_table.add('mysymbol', :mysymbol, :symbol)

    parsed = AsciiMath::parse("a + mysymbol + b", my_tokens_table.build)
    expect(parsed.ast).to eq(seq(identifier('a'), symbol('+'), ::AsciiMath::AST::Symbol.new(:mysymbol, 'mysymbol'), symbol('+'), identifier('b')))
  end

  it "should support replacing standard symbols" do
    my_tokens_table = AsciiMath::SymbolTableBuilder.new
    AsciiMath::Parser.add_default_parser_symbols(my_tokens_table)
    my_tokens_table.add('+', :foo, :symbol)

    parsed = AsciiMath::parse("a + b", my_tokens_table.build)
    expect(parsed.ast).to eq(seq(identifier('a'), ::AsciiMath::AST::Symbol.new(:foo, '+'), identifier('b')))
  end
end