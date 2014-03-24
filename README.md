# Ruby Adaptive-Images
This is a ruby port of Adaptive-Images (http://adaptive-images.com/, originally by Matt Wilcox). It does not contain all features, but it does more or less the same in the same way. It uses ImageMagick (via mini_magick) in stead of GD.

It runs as a sinatra application that can be mounted using Rack.

# Installation

To install, run: `gem install rai`

# Configuration

Put something like this in your config.ru:

```
require 'rai'

map '/gallery' do
  Rai::App.set :img_path, '/path/to/your/images'
  Rai::App.set :cache_path, '/path/to/your/cache'
  run Rai::App
end

```

## Settings

### :watch_cache
Keep an eye on the cache to see if it needs updating.
Values: true/false
Default: true

### :resolutions
Resolution break-points (screen widths).
Value: array
Default: [1382, 992, 768, 480, 320]

### :jpg_quality
JPG compression ratio, 0-100.
Value: integer, 0-100
Default: 75

### :sharpen
Wether image should be sharpened or not.
Value: true/false
Default: true

### :cache_max_age
Browser cache TTL
Value: integer, seconds
Default: 60*60*24*7 (7 days)

### :img_path
Where images are placed.
Value: string, path
Default:File.join(File.dirname(__FILE__), 'images')

### :cache_path
Where cached versions are placed.
Value: string, path
Default: File.join(File.dirname(__FILE__), 'images', 'cache')

# Author
Kim Nørgaard <jasen@jasen.dk>

