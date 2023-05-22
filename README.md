# Rick and Morty API
### Now with more information

## Setup
This is a relatively simple Rails app. Once you are in the directory, run

```
> bundle install
> rake db:migrate
> rails s
```

and everything should come up at `http://localhost:3000/character?name=whatever`.

The HTML renders are still available, under `http://localhost:3000/characters/search?name=whatever`.

## Why migrate?
Since this application passes queries along to [the Rick and Morty API](https://rickandmortyapi.com/documentation/),
there is no need for a database to hold character data. So, you may be wondering
why this application has migrations to run.

Rails is rather opinionated, and the standard flow is one where a controller
fetches data into an ActiveRecord model object, which is then passed along to a
view that will render that model into HTML or JSON. We can go along with this
flow, and can fetch data from the API that we then hydrate into ActiveRecord
models that the views will render.

### Alternatives
Instead of using the default of views rendering ActiveModel objects,
the data could have been represented by
[Dry-Struct objects](https://dry-rb.org/gems/dry-struct/1.6/) and the views
updated to render those instead. However, I was already working in the Rails
ecosystem, so I saw no reason to change so much of the default code just to
avoid running migrations. At that point, we could lean into the Dry-rb
ecosystem for the data and [Roda](http://roda.jeremyevans.net/) for routing,
or use [Grape](https://www.ruby-grape.org/) instead.

## GraphQL
The Rick and Morty API offers both REST and GraphQL endpoints. The REST endpoint
is universal, and can be accessed with barely more than an HTTP client. However,
dealing with the pagination to retrieve all the character and episode data for
a given request, while not insurmountable, led me to choose the GraphQL
endpoint. Github's [GraphQL client
gem](https://github.com/github/graphql-client) was well documented, and using it was straightforward.

Since I only had the one query, I placed the query definition in the RMApi
client file. In a more real world application, there would be multiple queries,
which I would define in separate files for readability and ease of management.

## Appearances
The "season count" algorithm to determine the number of appearances by season
was pretty straightforward. The biggest hurdle was retrieving the data in the
first place, which is one of the reasons I mentioned above for choosing GraphQL
over REST. Once I had that data, I created a `parse` method that removed the
`episode` key from the hash of character data, then `map`ped through the episode
information. Each `episode` was a code in the format `SxxEyy` for Season xx and
Episode yy. Since we only wanted the number of appearances per season, I scraped
the season information

```
season_code = code[0..2]
```
and used that as the key in the `appearances` hash, with the value being the
current count of appearances. Since I defined the hash using
`Hash.new{|h,k| h[k] = 0 } `, I was able to avoid testing if I already had a
value for a given season, and it would simply default to zero for a new key.

Then, after all appearances were calculated, I `join`ed them into a single
string and added it to the character hash with the "appearances" key. This meant
once the parsed character hash was returned, I could pass it to
`Character.new` and I would have a hydrated Character object to render in my
views.

## Caching
Part 2 of the exercise involved caching the result of the appearances
calculations. Since the exercise specified using Rails overall, I went ahead and
used Rails for the caching as well, and cached the result of the call to
`parse`:

```
  def self.parse(char_hash)
    Rails.cache.fetch([:episodes, char_hash["id"]], expires_in: 10.minutes)
```

Since this method receives the entire character hash, we have the `id` returned
by the Rick and Morty API. I used that as a sane key for the caching, and I
prefixed it with `:episodes` in case we were using the Rails cache elsewhere in
our application (or might want to in the future). 

1. How would you ensure that your cache is efficient but also up to date?

I used the argument `expires_in: 10.minutes` to set a time to live for this
information in the Rails cache. After ten minutes, this will expire, and we
will recalculate the appearances per season for a given character's ID.

2. Can you think of any other way to improve the performance of your service?

We still fetch data from the Rick and Morty API, even if we've done this search
before and skip calculating the appearances for each of the characters returned.
If we wanted to save even more time, we could cache the entire result set,
perhaps using the name we are trying to search for in the cache key:
`[:rmapi_fetch, search_name]`.

We could also look at different backends for the Rails cache. By default, Rails
used [Memcached](https://memcached.org/about), which is a very fast in memory
key/value store. It scales very well, so we probably wouldn't need to worry
about different cache stores unless we had multiple instances of our app
running. In that case, we could potentially use Redis for all of the apps, and
if one instance cached information, the other instances of the apps could then
use that cache to improve performance.

3. What are the upsides and downsides of your implementation?

Some upsides of using Rails caching include strong support and extensive
testing, since it's baked into Rails. This also means it's very easy to use,
just a few lines of code and potentially some configuration in an environment
file.

The biggest downside of the Rails cache is that, since it'd baked into Rails,
it "just works, which is a little magical. You don't get to see the internals
of how the cache works, but I don't see that as a huge downside except in
teaching situations. The less code you have to write yourself, the smaller the
chance of introducing your own bugs.
