require 'rexml/document'

# Uses Yahoo's fantastic weather RSS feed to resolve the weather information for either
# (American) zip codes or search queries. "More info":http://developer.yahoo.com/weather
class Weather

  # Yahoo's RSS weather service offers a numerical code that describes the conditions of a
  # forecasted day. Jay went through these codes creating the following array of Asterisk's
  # GSM audio files that best represent each condition. The numerical code associates with
  # the respective index in this array (error 0 is tornado, etc). When pulling an String from
  # this array, be sure to call the split() method on it to break it up between spaces!
  WEATHER_CODES = ["tornado", "storm", "hurricane", "severe thunderstorm", "thunderstorm",
    "rainy snowy", "rainy sleet", "snowy sleet", "icy misty", "misty", "icy rainy", "rainy",
    "rainy", "snowy", "snowy", "snowy", "snow", "hail", "sleet", "", "foggy", "foggy", "foggy",
    "", "windy", "low temperature", "cloudy", "mostly cloudy in-the evening",
    "mostly cloudy in-the day", "partly cloudy in-the evening", "partly cloudy in-the day",
    "clear in-the evening", "sunny", "good in-the evening", "good in-the day",
    "partially rainy with hail", "high temperature", "thunderstorm", "scattered thunderstorm",
    "scattered thunderstorm", "scattered rain", "snowy", "scattered snow", "snowy",
    "partly cloudy", "thunderstorm", "snowy", "thunderstorm"]
    
  DAYS = %w(sunday monday tuesday wednesday thursday friday saturday)
  DAYS_ABBREV = DAYS.abbrev
  
  def self.report where
    w = weather where
    nextdays = DAYS.dup
    nextdays += nextdays.slice! 0, Time.now.wday
    nextdays.slice! 4, 7 # Only a four-day forecast
    
    today = w.forecasts[nextdays.shift]
    rep = %W(weather is-currently #{w.current.temp} degrees today high #{today.high} low #{today.low}) + w.current.desc
    
    tomorrow = w.forecasts[nextdays.shift]
    rep += %W(weather tomorrow high #{tomorrow.high} low #{tomorrow.low}) + tomorrow.desc
    
    until nextdays.empty? do
      day = w.forecasts[nextdays.shift]
      rep += %W(weather #{4 - nextdays.size} days from now high #{day.high} low #{day.low}) + day.desc
    end
    rep
  end
  
  def self.weather where
    debug "Resolving ID"
    id = where.simplify.is_a?(Fixnum) ? where : get_id(where)
    debug "Getting Yahoo Data"
    url = "http://xml.weather.yahoo.com/forecastrss/#{id}_#{($HELPERS['weather'].units || 'fahrenheit')[0].chr}.xml"
    begin xml = REXML::Document.new open(url).read rescue return nil end
    xml2hash xml.elements
  end
  
  private
  def self.xml2hash xml
    hash = { :current => {}, :forecasts => {} }
    hash.current.temp = xml['/rss/channel/item/yweather:condition/@temp'].to_s
    hash.current.desc = WEATHER_CODES[xml['/rss/channel/item/yweather:condition/@code'].to_s.to_i].split || []
    forecasts = {}
    xml.each '//yweather:forecast' do |day|
      ats = day.attributes
      fullname = DAYS_ABBREV[ats['day'].downcase]
      hash.forecasts[fullname] = {}
      hash.forecasts[fullname].low = ats['low']
      hash.forecasts[fullname].high = ats['high']
      hash.forecasts[fullname].desc = WEATHER_CODES[ats['code'].to_i].split
    end
    hash
  end
  
  def self.get_id where
    query = URI.escape where
    response = open("http://xoap.weather.com/search/search?where=#{query}").read
    response.gsub!(/<\?.*\?>/,'').gsub!(/<\!--.*-->/, '')
    doc = REXML::Document.new response
    results = doc.elements.to_a('/search/loc')
    if results.size.zero?
      warn "Couldn't resolve weather information for #{where}"
      nil
    else results[0].attributes['id']
    end
  end
end

def weather(loc="Dallas, Texas") Weather.weather loc end
def weather_report(loc="Dallas, Texas") Weather.report loc end
