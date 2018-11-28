require 'geocoder'
require 'json'
require 'sinatra'

set :bind, '0.0.0.0'

# Provided coordniates, return the closes address
post '/coords' do
    d = JSON.parse(request.body.read.to_s)
    coords = [d[0], d[1]]
    results = Geocoder.search(coords)

    # Return 404 if no results are found
    if results.length == 0
        status 404
        return
    end

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

    return address.to_json
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