require 'rubygems'
require 'ruby-growl'

require 'flvvr/yidio'


if ARGV.empty?
  puts "Try running #{$0} SHOW_NAME SEASON EPISODE [WHICH_DOWNLOAD_LINK]"
  puts %Q{e.g. #{$0} "the big bang theory" 1 11}
  exit
end


which_link = (ARGV[3] || 1).to_i
ep = Flvvr::Show::Episode.new(ARGV[0], ARGV[1] || 1, ARGV[2] || 1)
ep.stats
streaming_link = ep.streaming_link(which_link)
`echo "#{streaming_link}"| pbcopy`
puts "Copied #{streaming_link} to clipboard"

puts "If you want to watch immediately, use jDownloader to download this URL."
puts "Opening higher quality link from megaupload now (unfortunately VLC must wait for entire download to complete)."

download_link = ep.download_link(which_link)
if download_link.nil?
  puts ' ** No download link found! '
else
  `open #{download_link}`

  puts "\n\nPress enter when you've entered the captcha, and I'll send a growl notification when the download link will be ready for you to click."
  msg = STDIN.gets.chomp
  exit if msg[/x/i]

  puts "OK, counting down 45 seconds..."
  sleep(45)
  g = Growl.new "localhost", "flvvr", ["Notification"]
  g.notify "Notification", "Flvvr", "MegaUpload should be ready to download.", 0, true # Sticky notification
  puts "Go press download!"
end