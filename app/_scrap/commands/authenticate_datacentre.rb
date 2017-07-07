class AuthenticateDatacentre
  prepend SimpleCommand

  def initialize(symbol, password)
    @symbol = symbol
    @password = password
  end

  def call
    JsonWebToken.encode(datacentre: datacentre.id) if datacentre
  end

  private

  attr_accessor :symbol, :password

  def datacentre
    puts symbol
    puts password
    datacentre = Datacentre.find_by(symbol: symbol)
    return datacentre if datacentre && datacentre.authenticate(password)

    errors.add :datacentre_authentication, 'invalid credentials'
    nil
  end
end
