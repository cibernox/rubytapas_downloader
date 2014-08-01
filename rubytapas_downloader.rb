require 'httparty'
require 'nokogiri'

USERNAME = ENV['RTAPAS_USERNAME'] || "email-used@in-registration.com"
PASSWORD = ENV['RTAPAS_PASSWORD'] || "your-password-here"
DOWNLOAD_DIR = ARGV.pop || File.dirname(__FILE__)
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
    Dir.exist?(File.join(DOWNLOAD_DIR, title))
  end

  def download!
    verify_download_dir!
    Dir.mkdir(File.join(DOWNLOAD_DIR, title))
    files.each do |filename, url|
      file_path = File.join(DOWNLOAD_DIR, title, filename)
      system %Q{curl -o "#{file_path}" -b #{COOKIE_FILE} -d "username=#{USERNAME}&password=#{PASSWORD}" #{url}}
    end
  end

  def verify_download_dir!
    return true if Dir.exists?(DOWNLOAD_DIR)
    require 'fileutils'
    FileUtils.mkdir_p(DOWNLOAD_DIR)
  end
end

if __FILE__ == $0
  RubytapasDownloader.new.launch
end
