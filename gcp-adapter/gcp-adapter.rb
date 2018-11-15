require 'date'
require "httparty"
require 'json'
require 'optimist'
require "google/cloud/pubsub"

# Poll the USGS feed for real-time earthquake readings
def pull_hourly_earthquake(lastTime, opts)
    # Get all detected earthquakes in the lasthour
    url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
    response = HTTParty.get(url)
    j = JSON.parse(response.body)

    # Keep track of latest recorded event, reporting all
    # if none have been tracked so far
    cycleLastTime = lastTime

    # Parse each reading and send new ones to the GCP PubSub topic
    j["features"].each do |f|
        id = f["id"]
        time = f["properties"]["time"]

        if time > lastTime
            datetime = DateTime.strptime(time.to_s,'%Q')
            id = f["id"]
            mag = f["properties"]["mag"]
            long = f["geometry"]["coordinates"][0]
            lat = f["geometry"]["coordinates"][1]
            msg = {
                time: datetime,
                id: id,
                mag: mag,
                lat: lat,
                long: long
            }
            publish_message(msg.to_json, opts)
            puts msg
        end

        # Keep track of latest reading
        if time > cycleLastTime
            cycleLastTime = time
        end
    end

    lastTime = cycleLastTime
    return lastTime
end

# Write a message to the GCP PubSub topic
def publish_message(message, opts)
    pubsub = Google::Cloud::Pubsub.new(
        project_id: opts[:project],
        credentials: opts[:credentials]
    )
    
    puts "Publishing to #{opts[:topic]}"
    topic = pubsub.topic(opts[:topic])
    topic.publish(message)
end


# Parse CLI flags
opts = Optimist::options do
    version "0.1"
    banner <<-EOS
Poll USGS Real-Time Earthquake data and publish to GCP PubSub

Usage:
  ruby gcp_adapter.rb -t my-topic -p gcp-project -c /path/to/gcp/credentials

EOS
    opt :topic, "GCP PubSub Topic", :type => String
    opt :project, "GCP Project", :type => String
    opt :credentials, "Path to GCP JSON credentials", :type => String
    opt :frequency, "How often to poll USGS data", :default => 10
end

Optimist::die :topic, "Must define a GCP PubSub Topic" if opts[:topic].nil?
Optimist::die :project, "Must define a GCP Project" if opts[:project].nil?
Optimist::die :credentials, "Must define a path to the GCP JSON credentials" if opts[:credentials].nil?
Optimist::die :credentials, "#{opts[:credentials]} does not exist" unless File.exist?(opts[:credentials])

# Begin polling USGS data
lastTime = 0
puts "Polling every #{opts[:frequency]} seconds"
while true do 
    lastTime = pull_hourly_earthquake(lastTime, opts)
    sleep(opts[:frequency])
end