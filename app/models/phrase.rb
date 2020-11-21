require "pwqgen"

class Phrase
  attr_reader :string

  def initialize
    @string = Pwqgen.generate
  end
end
