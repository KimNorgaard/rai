require 'sinatra/base'
require 'mini_magick'
require 'fileutils'

module Rai
  class App < Sinatra::Base
    # keep an eye on the cache to see if it needs updating
    set :watch_cache, true
    # resolution break-points (screen widths)
    set :resolutions, [2560,1920,1440,1024,768,480]
    # jpg compression ratio, 0-100
    set :jpg_quality, 85
    # wether image should be sharpened or not
    set :sharpen, true
    # 7 days
    set :cache_max_age, 60*60*24*7
    # where images are placed
    set :img_path, File.join(File.dirname(__FILE__), '..', 'images')
    # where cached versions are placed
    set :cache_path, File.join(File.dirname(__FILE__), '..', 'images', 'rai-cache')
    # cookie name
    set :cookie_name, 'rai-resolution'

    get %r{.*?\.(jpg|jpeg|png|gif)$} do
      @img_file = File.join(settings.img_path, @request_path)
      not_found unless File.exists? @img_file
      @cache_file = File.join(settings.cache_path, @resolution.to_s, @request_path)
      @extension = params[:captures][0].downcase

      expires settings.cache_max_age, :private, :must_revalidate
      last_modified File.mtime(@img_file)

      if File.exists? @cache_file
        refresh_cache
      else
        update_cached_image
      end
      send_file @cache_file
    end

    before do
      @request_path = URI.decode(request.path_info)
      settings.resolutions.sort!{|x,y| y <=> x }
      @resolution = get_resolution
    end

    helpers do
      def get_resolution
        get_resolution_from_cookie || get_resolution_from_user_agent
      end

      def get_resolution_from_cookie
        if res_cookie = request.cookies[settings.cookie_name]
          cookie_data = res_cookie.split(',')
          total_width = client_width = cookie_data[0].to_i
          # the device's pixel density factor (physical pixels per CSS pixel)
          pixel_density = cookie_data[1] ? cookie_data[1].to_i : 1
          # by default use the largest supported break-point
          resolution = settings.resolutions.first

          total_width = client_width * pixel_density

          resolution =
            settings.resolutions.select {|res| total_width <= res}.last
          resolution ||= settings.resolutions.first

          if total_width > settings.resolutions.first
            resolution *= pixel_density
          end

          return resolution
        end
      end

      def get_resolution_from_user_agent
        is_mobile ? settings.resolutions.min : settings.resolutions.max
      end

      def is_mobile
        request.user_agent.downcase.match(/mobi|android|touch|mini/)
      end

      def refresh_cache
        return unless settings.watch_cache
        return if File.mtime(@cache_file) >= File.mtime(@img_file)

        File.delete @cache_file
        update_cached_image
      end

      def update_cached_image
        cache_dir = File.dirname(@cache_file)
        begin
          #Dir.mkdir(settings.cache_path, 0755) unless File.directory?(settings.cache_path)
          FileUtils.mkdir_p(cache_dir, :mode => 0755) unless File.directory?(cache_dir)
        rescue SystemCallError => e
          halt(500, "Unable to create caching directory. #{e}")
        rescue => e
          halt(500, "Unable to create caching directory. #{e}")
        end

        begin
          image = MiniMagick::Image.open(@img_file)
        rescue Exception => e
          halt(500, "Error loading image: #{e}")
        end

        # Do we need to downscale the image?
        if image[:width] <= @resolution
          @cache_file = @img_file
          return
        end

        ratio      = image["%[fx:w/h]"].to_f
        new_width  = @resolution
        new_height = (new_width*ratio).ceil

        if @extension == 'jpg'
          image.combine_options do |c|
            c.interlace 'plane'
            c.quality settings.jpg_quality
          end
        end

        if settings.sharpen
          radius    = 0.5
          sigma     = 0.5
          amount    = 1.0
          threshold = 0.02
          image.unsharp "#{radius}x#{sigma}+#{amount}+#{threshold}"
        end

        image.resize "#{new_width}x#{new_height}"

        begin
          image.write @cache_file
        rescue Exception => e
          halt(500, "Error writing cache file: #{e}")
        end
      end
    end

    not_found do
      "Not found: #{@request_path} not found."
    end
  end
end
