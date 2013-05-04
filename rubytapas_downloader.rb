require 'httparty'
require 'nokogiri'

USERNAME = "email-used@in-registration.com"
PASSWORD = "your-password-here"
COOKIE_FILE = 'cookies.txt' # by example

class RubytapasDownloader
  FEED_URL  = "https://rubytapas.dpdcart.com/feed"
  LOGIN_URL = "http://rubytapas.dpdcart.com/subscriber/login?__dpd_cart=8f511233-b72b-4a8c-8c37-fadc74fbc3a1"

  ##
  # Fetchs and parses the rss feed. Generates the episodes
  #
  def initialize
    rss = HTTParty.get(FEED_URL, basic_auth: { username: USERNAME, password: PASSWORD })
    @episodes = Nokogiri::XML(rss).css('item').map{ |item| Episode.new(item) }
  end

  ##
  # Downloads the new episodes with curl.
  #
  def launch
    puts "--- LAUNCHING RUBYTAPAS DOWNLOADER ---"

    puts "--- LOG IN AND SAVE COOKIE ---"
    login_and_save_cookie

    binding.pry
    new_episodes = @episodes.reject(&:downloaded?)
    count = new_episodes.size
    puts "#{count} NEW EPISODES"


    new_episodes.each_with_index do |episode, index|
      puts "DOWNLOADING #{episode.title} (#{index + 1} of #{count})"
      episode.download!
    end

    puts "--- FINISHED RUBYTAPAS DOWNLOADER ---"
  rescue Exception => e
    puts "--- EXCEPTION RAISED WHILE DOWNLOADING --"
    puts e.inspect
  ensure
    File.delete(COOKIE_FILE) if File.exist?(COOKIE_FILE)
  end

private

  ##
  # Logins with https and saves the cookie
  #
  def login_and_save_cookie
    system %Q{curl -c #{COOKIE_FILE} -d "username=#{USERNAME}&password=#{PASSWORD}" #{LOGIN_URL}}
  end

end


class Episode
  attr_accessor :title, :files

  ##
  # Extracts informations from the parsed XML node
  #
  def initialize(parsed_rss_item)
    @title = parsed_rss_item.css('title').text.gsub(/\s|\W/, '-').gsub('--','-')
    @files = {}
    parsed_description = Nokogiri::XML(parsed_rss_item.css('description').text)
    parsed_description.css('a').each do |link|
      @files[link.text] = link[:href]
    end
  end

  ##
  # Simplest approach: If there is a folder named like the episode, it is already downloaded
  # TODO: Per-file checking instead of just a folder checking
  #
  def downloaded?
    Dir.exist?(title)
  end

  ##
  # Downloads all the files
  #
  def download!
    Dir.mkdir(title)
    files.each do |filename, url|
      file_path = File.join(title, filename)
      system %Q{curl -o #{file_path} -b cookies.txt -d "username=#{USERNAME}&password=#{PASSWORD}" #{url}}
    end
  end
end


RubytapasDownloader.new.launch