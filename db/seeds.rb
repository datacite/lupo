# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

allocators = Allocator.create([{ name: Faker::StarWars.specie,  symbol: "DATACITE", id: 1  }, { name: Faker::StarWars.specie,  symbol: "ZOYA", id: 2  }])

datacentres = Datacentre.create([{ name: Faker::StarWars.character,  allocator: allocators.last  , symbol: "DATACITE.DATACITE", id:123  }, { name: Faker::StarWars.character,  allocator: allocators.first , symbol: "DATACITE.ALPHA", id:1  }])

prefixes = Prefix.create([{ prefix: Faker::Name.first_name, version: Faker::Number.between(1, 10) },{ prefix: Faker::Name.name, version:Faker::Number.between(1, 10) }])

datasets = Dataset.create([{ doi: Faker::PhoneNumber.phone_number, id: 1,  datacentre: datacentres.last, created: Faker::Time.between(2.days.ago, Date.today, :midnight)  }, { doi: Faker::PhoneNumber.phone_number, id: 3,  datacentre: datacentres.first, created: Faker::Time.between(2.days.ago,Date.today, :midnight)  }])
