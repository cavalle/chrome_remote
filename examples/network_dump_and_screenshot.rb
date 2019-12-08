require 'chrome_remote'
require 'base64'

chrome = ChromeRemote.client

# Enable events
chrome.send_cmd "Network.enable"
chrome.send_cmd "Page.enable"

# Setup handler to log network requests
chrome.on "Network.requestWillBeSent" do |params|
  puts params["request"]["url"]
end

# Navigate to github.com and wait for the page to load
chrome.send_cmd "Page.navigate", url: "https://github.com"
chrome.wait_for "Page.loadEventFired"

# Take page screenshot
response = chrome.send_cmd "Page.captureScreenshot"
File.write "screenshot.png", Base64.decode64(response["data"])
