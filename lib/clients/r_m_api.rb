require "graphql/client"
require "graphql/client/http"

###
# See https://github.com/github/graphql-client
# for more info
#
module RMApi
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("https://rickandmortyapi.com/graphql") do
    def headers(context)
      # Optionally set any HTTP headers
      { "User-Agent": "Test Client" }
    end
  end

  # Fetch latest schema on init, this will make a network request
  Schema = GraphQL::Client.load_schema(HTTP)

  # For production, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task
  #   GraphQL::Client.dump_schema(RMApi::HTTP, "path/to/schema.json")
  #
  # Schema = GraphQL::Client.load_schema("path/to/schema.json")

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
