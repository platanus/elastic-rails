# Elastic Rails

[![Build Status](https://travis-ci.org/platanus/elastic-rails.svg?branch=master)](https://travis-ci.org/platanus/elastic-rails)

Elasticsearch + Ruby on Rails made easy.

## Features

* Easy setup
* Chainable query DSL
* Easy to use results
* Seamless rails integration
* Multiple enviroment support
* Zero downtime index migrations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elastic-rails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elastic-rails

Finally execute the initialization script to generate configuration files:

    $ rails g es:init

## Usage overview

[For detailed usage reference check out the GUIDE]

Suppose that you already have a model called `Bike`, start by creating an index for it:

    rails g es:index Bike

This will generate a new index definition file in `app/indices/bike_index.rb`

Add some fields to the index:

```ruby
class BikeIndex < ElasticType
  # field types are extracted from the target model
  fields :brand_id, :model, :year, :price

  # you can also explicitly set the field type
  field :category, type: :term
  field :description, type: :string
  field :created_at, type: :time

  # you can also have nested documents, the following will require a nested PartIndex to be defined.
  nested :parts

  # you can override fields or create new ones
  def year
    object.batch.year
  end
end
```

Every time you create or change and index you will neeed to synchronize the Elasticsearch index mappings:

     rake es:remap

If you already have some data that needs to be indexed then run the reindex task:

     rake es:reindex

To add additional data call the index `import` or the model's `index_now` or `index_later` methods:

```ruby
some_bike.index_now # this will reindex only one record
some_bike.index_later # this will queue a reindexing job on the record
BikeIndex.import([bike_1, bike_2, bike_3]) # this will perform a bulk insertion
```

You can also setup automatic indexation/unindexation for a given model:

```ruby
class Bike < ActiveRecord::Base
  index on: :save
end
```

After some data has been added you can start quering:

```ruby
# List bikes of brand Trek or Cannondale, preferably 2015 or later models:
BikeIndex
  .must(brand: ['Trek', 'Cannondale'])
  .should(year: { gte: 2015 })
  .to_a

# List bikes of brand Trek, preferably 2015 or 2016, give higher score to 2016 models:
BikeIndex
  .must(brand: ['Trek', 'Cannondale'])
  .should(year: 2015)
  .boost(2.0) { should(year: 2016) }
  .to_a

# More score manipulation:
BikeIndex
  .coord_similarity(false) # disable coord similarity (no score normalization)
  .boost(0.0) { must(brand: ['Trek', 'Cannondale']) } # no score
  .boost(fixed: 1.0) { should(year: 2015) } # fixed score
  .boost(fixed: 2.0) { should(year: 2016) }
  .each_with_score { |bike, score| puts "#{bike.name} got score: #{score}" }

# Get average bike price by year and category, for bikes newer than 2014
BikeIndex
  .must(year: { gte: 2014 })
  .segment(:year)
  .segment(:category)
  .average(:price)
  .each { |keys, price| puts "#{keys[:year]}/#{keys[:category]} => #{price}" }

# Get average and maximum bike price for bikes newer than 2014
BikeIndex
  .must(year: { gte: 2014 })
  .compose do |c|
    c.average(:price)
    c.maximum(:price)
  end

# Search bikes ids that have shimano parts:
BikeIndex.must(parts: { brand: 'shimano' }).ids
```

## Missing features

The following are some features that we plan to implement in the future:

* Highlighting support
* Suggesters support
* Geo fields and queries support
* Custom analizers support
* More queries types support (multi-match, common-terms, wildcard, fuzzy, etc)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/platanus/elastic-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

