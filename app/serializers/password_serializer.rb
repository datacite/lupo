class PasswordSerializer < ActiveModel::Serializer
  cache key: 'password'

  attributes :password, :string
end
