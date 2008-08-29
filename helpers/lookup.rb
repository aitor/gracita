=begin Adhearsion metadata
  name: Number Metadata Lookup
  author: Jay Phillips
=end

require "hpricot"
require "open-uri"

def lookup number
  hash = {}
  url = "http://www.whitepages.com/9901/search/ReversePhone?phone=#{number}"
  doc = Hpricot open(url)

  # This div contains all the information we need, unless it's an unlisted number
  if (results = doc.at "#results_single_listing") then
    # This div's h3 contains the name of the caller
    hash[:first_name], hash[:last_name] = results.at('h3').inner_html.split(/,\s*/).reverse
    hash[:name] = hash[:first_name] + " " + hash[:last_name]
    
    # Now we just need the rest of the information contained in p's.
    meta = results/'p'
    meta.pop # Discard the useless p element

    hash[:number] = meta.pop.inner_html
    city_info = meta.pop.inner_html
    city_info = city_info.match /(.+), ([A-Za-z]{2}) (\d{5})/
    hash[:city]  = city_info[1]
    hash[:state] = city_info[2]
    hash[:zip]   = city_info[3]

    hash[:address] = meta.map(&:inner_html) * " "
  elsif (results = doc.at "#results_single_phone_info") then
    meta = results/'span'
    hash[:location] = (meta.pop.inner_html.match /Location: (.*)/)[1]
  end
  
  if hash[:first_name] or hash[:last_name] then
    hash[:composite] = "#{hash[:first_name]} #{hash[:last_name]}"
  else
    hash[:composite] = hash[:location]
  end
  
  hash
end