require 'rubygems'
require 'ruby-growl'

require 'flvvr/yidio'


if ARGV.empty?
  puts "Try running #{$0} SHOW_NAME SEASON EPISODE [WHICH_DOWNLOAD_LINK]"
  puts %Q{e.g. #{$0} "the big bang theory" 1 11}
  exit
end


which_link = ARGV[3] || 1
ep = Flvvr::Show::Episode.new(ARGV[0], ARGV[1] || 1, ARGV[2] || 1)
ep.stats
link = ep.download_link(which_link)
`echo "#{link}"| pbcopy`
puts "Copied #{link} to clipboard"

puts "If you want to watch immediately, use jDownloader to download this URL."
puts "Opening higher quality link from megaupload now (unfortunately VLC must wait for entire download to complete)."

`open #{link.gsub('video.com', 'upload.com')}`

puts "\n\nPress enter when you've entered the captcha, and I'll send a growl notification when the download link will be ready for you to click."
msg = STDIN.gets.chomp
exit if msg[/x/i]

puts "OK, counting down 45 seconds..."
sleep(45)
g = Growl.new "localhost", "flvvr", ["Notification"]
g.notify "Notification", "Flvvr", "MegaUpload should be ready to download.", 0, true # Sticky notification
puts "Go press download!"
