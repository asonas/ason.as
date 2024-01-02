require 'mini_exiftool'
require 'mini_magick'

def resize_image(image_path)
  image = MiniMagick::Image.new(image_path)

  if image.width > 2000 || image.size > 500 * 1024
    image.resize "2000x2000>"
    image.quality 80    # Adjust quality to reduce file size further if needed
    image.write image_path
    puts "Resized: #{image_path}"
  else
    puts "No need to resize: #{image_path}"
  end
end

def remove_gps_data(image_path)
  photo = MiniExiftool.new image_path

  # GPS情報が含まれている場合、それらの値をnilに設定して削除する
  if photo.gps_latitude || photo.gps_longitude
    photo.gps_latitude = nil
    photo.gps_longitude = nil
    photo.gps_altitude = nil
    photo.save
    puts "Removed GPS data from #{image_path}"
  else
    puts "No GPS data found in #{image_path}"
  end
end

Dir.glob('source/images/articles/*').each do |file_path|
  next unless File.file?(file_path) && ['.jpg', '.jpeg', '.png'].include?(File.extname(file_path).downcase)
  resize_image(file_path)
  remove_gps_data(file_path)
end
