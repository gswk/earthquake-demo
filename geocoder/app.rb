require 'geocoder'
require 'json'
require 'pg'
require 'sinatra'

set :bind, '0.0.0.0'

DB_HOST = ENV["DB_HOST"] || 'localhost'
DB_DATABASE = ENV["DB_DATABASE"] || 'geocode'
DB_USER = ENV["DB_USER"] || 'postgres'
DB_PASS = ENV["DB_PASS"] || 'password'

conn = PG.connect( dbname: DB_DATABASE, host: DB_HOST, password: DB_PASS, user: DB_USER)
puts "Connected to database"

# Create table if it doesn't exist
conn.exec "CREATE TABLE IF NOT EXISTS events (
    id varchar(20) NOT NULL PRIMARY KEY,
    timestamp timestamp,
    lat double precision,
    lon double precision,
    mag real,
    address text
);"

# Store event in database
post '/' do
    d = JSON.parse(request.body.read.to_s)
    address = coords_to_address(d["lat"], d["long"])
    id = d["id"]
    conn.prepare("insert_#{id}", 'INSERT INTO events VALUES ($1, $2, $3, $4, $5, $6)')
    conn.exec_prepared("insert_#{id}", [d["id"], d["time"], d["lat"], d["long"], d["mag"], address.to_json])
end

def coords_to_address(lat, lon)
    coords = [lat, lon]
    results = Geocoder.search(coords)

    a = results.first
    address = {
        address: a.address,
        house_number: a.house_number,
        street: a.street,
        county: a.county,
        city: a.city,
        state: a.state,
        state_code: a.state_code,
        postal_code: a.postal_code,
        country: a.country,
        country_code: a.country_code,
        coordinates: a.coordinates
    }

    return address
end

# Provided coordniates, return the closes address
post '/coords' do
    d = JSON.parse(request.body.read.to_s)
    lat = d[0]
    lon = d[1]
    result = coords_to_address(lat, lon)
    # coords = [d[0], d[1]]
    # results = Geocoder.search(coords)

    # Return 404 if no results are found
    # if results.length == 0
    #     status 404
    #     return
    # end

    return result.to_json
end

# Given an address, return the coordinates
post '/address' do
    d = request.body.read.to_s
    results = Geocoder.search(d)
    
    # Return 404 if no results are found
    if results.length == 0
        status 404
        return
    end
    
    coords = "[#{results.first.coordinates[0]}, #{results.first.coordinates[1]}]"
    return coords
end

# Return the distance (in miles) between two sets of coordinates
post '/distance' do
    d = JSON.parse(request.body.read.to_s)
    result = Geocoder::Calculations.distance_between(d[0], d[1])
    return result.to_s
end