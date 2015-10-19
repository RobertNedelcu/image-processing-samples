  
module Smoothing

  PI = Math::PI
  E = Math::E 

  def gauss_weights_by_line(stdev) 
    center_line = []
    line_one = []
    line_two = []
    for x in 3..5 
      for y in 3..5
        center_line << [x,y] if x == 3
        line_one << [x,y] if x == 4
        line_two << [x,y] if x == 5
      end
    end
    all_lines = [center_line, line_one, line_two]
    cx, cy = 3, 3
    
    gauss_line_weights = []   
      
    base = (1 / ((2 * PI) * (stdev ** 2)))
    exp_denominator = (-1) * (2 * (stdev ** 2))
    all_lines.each do |line|
      gauss_weights = []
      line.each do |nx, ny|
        dx = cx - nx 
        dy = cy - ny
        exp_numerator = (dx ** 2) + (dy ** 2)
        exponent = exp_numerator / exp_denominator
        multiplier = E ** exponent
       
        gauss_weight = base * multiplier
        gauss_weights << gauss_weight
      end
      gauss_line_weights << gauss_weights
    end
    return gauss_line_weights
  end

  def gauss_vertical_lines(rgb_hash, width, height)
    x_lines = {}
    for x in 0..(width - 1)
      for my in 0..(height - 1)
        s_y = (my - 2) >= 0 ? (my - 2) : 0
        f_y = (my + 2) < height ? (my + 2) : (height - 1)
        line = []
        for y in s_y..f_y
          img_val = rgb_hash[[x,y]]
          line << img_val
        end
        x_lines[[x, my]] = line 
      end
    end
    return x_lines
  end

  def gaussian_blur(rgb_hash, stdev, width, height)
    gaussian_hash = {}

    x_lines = gauss_vertical_lines(rgb_hash, width, height)
    
    all_line_weights = gauss_weights_by_line(stdev)

    rgb_hash.each_key do |pos|
      px, py = pos[0], pos[1]
      current_val = rgb_hash[pos]
      sx = px - 2 >= 0 ? px - 2 : 0
      fx = px + 2 < width ? px + 2 : width - 1
      twentyfive_pix_area = []
      for x in sx..fx
        twentyfive_pix_area << x_lines[[x, py]]
      end

      center_index_arr = 2
      if twentyfive_pix_area.length < 5 && sx == 0
      	center_index_arr = px 
      end

      sy = py - 2
      y_center_index = sy >= 0 ? 2 : py
      
      weighted_vals = []
      sum_weights = 0

      twentyfive_pix_area.each_with_index do |line, i|
      	idiff = (i - center_index_arr).abs
        line.each_with_index do |rgb, li|
          rgb_weighted_vals = []
          li_diff = (li - y_center_index).abs
          which_line = all_line_weights[idiff]
          weight = which_line[li_diff]
          
          sum_weights += weight
          rgb.each {|v| rgb_weighted_vals << (v * weight)}
          weighted_vals << rgb_weighted_vals
        end
      end
      #add the remaining, nearly-negligble weights of pixels outside of 25 pix neighborhood to the working position
      origin_weight = 1 - sum_weights  
      original_rgb_arr = rgb_hash[[px,py]]
      origin_weighted_vals = [] 
      #add the working positions added weighted value to the weighted_vals array
      original_rgb_arr.each {|value| origin_weighted_vals << (origin_weight * value)} 
      weighted_vals << origin_weighted_vals

      gauss_origin_val = [0,0,0]
      weighted_vals.each do |r,g,b|
      	gauss_origin_val[0] += r 
      	gauss_origin_val[1] += g 
      	gauss_origin_val[2] += b 
      end
      gauss_origin_val.map! {|v| v = v.round}
      gaussian_hash[pos] = gauss_origin_val
    end
    return gaussian_hash 
  end


end