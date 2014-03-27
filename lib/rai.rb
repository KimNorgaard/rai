require 'sinatra/base'
require 'mini_magick'
require 'fileutils'

require_relative 'rai/helpers'

module Rai
  class App < Sinatra::Base
    # Keep an eye on the cache to see if it needs updating
    set :watch_cache, true

    # Resolution break-points (screen widths)
    set :resolutions, [2560, 1920, 1440, 1024, 768, 480]

    # JPG compression ratio, 0-100
    set :jpg_quality, 85

    # Sharpen images after resize
    set :sharpen, true

    # Cache Time-To-Live
    set :cache_max_age, 60*60*24*7

    # Image location
    set :img_path, File.join(File.dirname(__FILE__), '..', 'images')

    # Cache location
    set :cache_path, File.join(File.dirname(__FILE__), '..', 'images', 'rai-cache')

    # Cookie name
    set :cookie_name, 'rai-resolution'

    # Supported image types
    set :supported_image_types, ['jpg', 'jpeg', 'gif', 'png']

    helpers Rai::Helpers

    get %r{.*?(\.(?<image_type>[\w]+))?$} do
      halt(406, "No image type/extension given") unless params[:image_type]
      halt(406, "Unsupported image type: #{params[:image_type]}") unless settings.supported_image_types.include? params[:image_type]

      @request_path     = URI.decode(request.path_info)
      @resolution       = get_resolution
      @requested_image  = File.join(settings.img_path, @request_path)
      not_found unless File.file? @requested_image
      @cached_image     = File.join(settings.cache_path, @resolution.to_s, @request_path)

      # Just send the original image if the nocache parameter is set to 1
      send_file @requested_image if params[:nocache] == '1'

      # Generate image or use cached version
      update_image

      # Set caching headers
      expires settings.cache_max_age, :private, :must_revalidate
      last_modified File.mtime(@requested_image)

      send_file @cached_image
    end

    not_found do
      "Not Found: #{request.path}"
    end
  end
end
