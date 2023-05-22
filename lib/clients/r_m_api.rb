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

  NAME_QUERY = RMApi::Client.parse <<-GRAPHQL
  query($name: String) {
    characters(filter: {name: $name}) {
      results {
        id
        name
        status
        species
        gender
        image
        episode {
          episode
        }
      }
    }
  }
  GRAPHQL

  def self.filter(name:)
    gql_response = Client.query(NAME_QUERY, variables: {name: name})

    gql_response.data.characters.results.map do |result|
      parse(result.to_h.dup)
    end
  end

  def self.parse(char_hash)
    Rails.cache.fetch([:episodes, char_hash["id"]], expires_in: 10.minutes) do
      appearances = Hash.new{|h,k| h[k] = 0 }

      char_hash.delete("episode").map do |episode|
        code = episode["episode"]
        season_code = code[0..2]

        appearances[season_code] += 1
      end

      char_hash["appearances"] = appearances.map{|k,v| "#{k}:#{v}" }.join(', ')

      char_hash
    end
  end
end
