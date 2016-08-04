class <%= class_name %>Index < Elastic::Type
  # Index model fields by adding field definitions.
  #
  # Some examples:
  #
  # fields :foo, :bar
  # field :timestamp, type: :date
  # field :category, type: :term
  # field :complex, transform: -> { "#{property_1}/#{property_2}" }
  # field :custom
  #
  # def custom
  #   "foobar"
  # end
  #
end
