module Rai
  module Helpers
    def get_resolution
      settings.resolutions.sort!{|x,y| y <=> x }
      get_resolution_from_cookie || get_resolution_from_user_agent
    end

    def get_resolution_from_cookie
      return false unless res_cookie = request.cookies[settings.cookie_name]

      if res_cookie !~ /^[0-9]+[,]*[0-9\.]+$/
        response.delete_cookie settings.cookie_name
      else
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

    def update_image
      # Refresh the image if the cached version is too old
      if File.exists? @cached_image
        return unless settings.watch_cache
        return if File.mtime(@cached_image) >= File.mtime(@requested_image)
        File.delete @cached_image
      end

      begin
        image = MiniMagick::Image.open(@requested_image)
      rescue Exception => e
        halt(500, "Error loading image: #{e}")
      end

      # Do we need to downscale the image?
      if image[:width] <= @resolution
        @cached_image = @requested_image
        return
      end

      cache_dir = File.dirname(@cached_image)

      begin
        FileUtils.mkdir_p(cache_dir, :mode => 0755) unless File.directory?(cache_dir)
      rescue SystemCallError => e
        halt(500, "Unable to create caching directory. #{e}")
      rescue => e
        halt(500, "Unable to create caching directory. #{e}")
      end

      ratio      = image["%[fx:w/h]"].to_f
      new_width  = @resolution
      new_height = (new_width*ratio).ceil

      if params[:image_type] == 'jpg'
        image.combine_options do |c|
          c.interlace 'plane'
          c.quality settings.jpg_quality
        end
      end

      image.resize "#{new_width}x#{new_height}"

      if settings.sharpen
        radius    = 0.5
        sigma     = 0.5
        amount    = 1.0
        threshold = 0.02
        image.unsharp "#{radius}x#{sigma}+#{amount}+#{threshold}"
      end

      begin
        image.write @cached_image
      rescue Exception => e
        halt(500, "Error writing cache file: #{e}")
      end
    end
  end
end
