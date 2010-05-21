#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'


# Quick script to help with watching shows online.
# Given a show name, season, and episode number, returns the most promising megavideo.com link from yidio.com's list of links.
# The URL is then suitable for pasting into jDownloader to download the flv file, if that sort of thing appeals to you.  

# Rationale - attempting to watch big bang theory online, all the episodes have audio.video sync issues.  Downloading and playing
# in VLC allows you to fix the audio on the fly (using the f and g keys).
module Flvvr
  PREFERRED_SITE = 'www.megavideo.com'
  module Yidio
    class URL
      attr_accessor :url
      BASE = "http://www.yidio.com"
    
      def self.link_page_for_episode(show, season, episode)
        Flvvr::Yidio::URL.new "show/#{show.downcase.gsub(/\W/, '-')}/season-#{season}/episode-#{episode}/links.html"
      end
    
      def initialize(relative)
        @url = "#{BASE}/#{relative.to_s.gsub(/^\//, '')}"
      end
        
      def to_s
        @url
      end
    end
  
    class Link
      attr_accessor :redirect_url, :title, :site
      def initialize(redirect_url, title, site)
        @redirect_url = redirect_url.to_s
        @title = title.to_s
        @site = site.to_s
      end
    
      def hq?
        !! @title[/\bhq\b/i]
      end
    
      # Sort with HQ links first
      def <=>(other)
        if self.hq?
          return other.hq? ? 0 : -1
        else 1
        end
      end
    
      def source_url
        Nokogiri::HTML(open( @redirect_url )).at_css('div.play a').attributes['href'].to_s.scan(/playVideo\("(.+?)"\)/).flatten.first
      end
    end
  
    class LinkCollection
      attr_accessor :raw_links
      def initialize
        @raw_links = []
      end
        
      def self.for_episode(show, season, episode)
        yidio = Flvvr::Yidio::URL.link_page_for_episode(show, season, episode)
        link_page = Nokogiri::HTML(open( yidio.url ))
        collection = self.new
      
        # Check for no links available
        return collection if link_page.css('h2').any?{|header| header.content == '0 Official Results'}
      
        link_page.css('ul.results li').each do |li|
          if site = li.at_css('a.link')
            title = li.at_css(".ttl a")
            redirect_url = Flvvr::Yidio::URL.new( title.attributes['href'] )
            collection.raw_links << Flvvr::Yidio::Link.new(redirect_url, title.content, site.content)
          end
        end
      
        return collection
      end
    
      def size
        @raw_links.length
      end
    
    
      def links
        @raw_links.sort
      end
    
      def at(site)
        links.select{|l| l.site == site}
      end
    
      def preferred_download_at(site)
        at(site).first
      end
    end
  
  end


  module Show
    class Episode
      attr_accessor :show, :season, :episode, :link_collection
      def initialize(show, season, episode)
        @show = show
        @season = season
        @episode = episode
        @link_collection = Flvvr::Yidio::LinkCollection.for_episode(show, season, episode)
      end
    
      def stats
        puts " ***" * 15
        puts %Q{\tSearching for "#{@show}" (Season #{@season}, Episode #{@episode})}
        puts "\tFound #{@link_collection.size} total links, #{@link_collection.at( PREFERRED_SITE ).length} at #{PREFERRED_SITE}"
        if @link_collection.size.zero?
          puts "\n\t\t\t NO RESULTS FOUND.\n\n"
          puts "\tAre you sure the episode exists and the show name is correct?"
          puts "\tYidio URL: #{Flvvr::Yidio::URL.link_page_for_episode(@show, @season, @episode)}"
        end
        puts " ***" * 15
      end

      def download_links
        link_collection.at( PREFERRED_SITE ).map(&:source_url)
      end

      def download_link(n = 1)
        n = n.to_i.zero? ? 0 : n.to_i - 1
        link = link_collection.at( PREFERRED_SITE )[n]
        link ? link.source_url : nil
      end
    end
  end

end
