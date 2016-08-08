require 'json'
require 'uri'
require 'net/http'
require 'rom'
require 'rom-http'

class RequestHandler
  def call(dataset)
    uri = URI(dataset.uri)
    uri.path = "/#{dataset.name}/#{dataset.path}"
    uri.query = URI.encode_www_form(dataset.params)

    http = Net::HTTP.new(uri.host, uri.port)
    request_klass = Net::HTTP.const_get(ROM::Inflector.classify(dataset.request_method))

    request = request_klass.new(uri.request_uri)
    dataset.headers.each_with_object(request) do |(header, value), request|
      request[header.to_s] = value
    end

    response = http.request(request)
  end
end

class ResponseHandler
  def call(response, dataset)
    Array([JSON.parse(response.body)]).flatten
  end
end

class Users < ROM::Relation[:http]
  dataset :users

  # You can also define a schema block
  # which will use dry-types' Dry::Types['hash']
  # coercion to pre-process your data
  schema do
    attribute 'id', 'strict.int'
    attribute 'name', 'strict.string'
    attribute 'username', 'strict.string'
    attribute 'email', 'strict.string'
    attribute 'phone', 'strict.string'
    attribute 'website', 'strict.string'
  end

  def by_id(id)
    with_path(id.to_s)
  end
end

configuration = ROM::Configuration.new(:http, {
    uri: 'http://jsonplaceholder.typicode.com',
    headers: {
        Accept: 'application/json'
    },
    request_handler: RequestHandler.new,
    response_handler: ResponseHandler.new
})

configuration.register_relation(Users)
container = ROM.container(configuration)

pp container.relation(:users).by_id(1).to_a