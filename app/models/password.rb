require 'pwqgen'

class Password
  include Authenticable
  attr_reader :string

  def initialize(user, client)
    @client = client
    @current_user = user
    @string = Pwqgen.pwqgen(n_words: 5)
    fail unless @string
    save_password
  end

  def save_password
    fail unless @client.update(password: encrypt_password(@string))
  end

end
