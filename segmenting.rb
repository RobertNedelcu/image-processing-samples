
module Segmentation
  
  #maxima thresholds:
  SIZE_THRESH = 15
  HARD_STDEV = 1.3  #boundary standard deviation for first segmentation
  SOFT_STDEV = 2.0 #more liberal threshold for further segmentation

  #returns the inclusive center of a group of pixels
  def find_center(cluster)
    sumx = 0; sumy = 0
    total = cluster.length
    cluster.each do |x,y|
      sumx += x 
      sumy += y
    end
    xavg = (sumx.to_f / total).round 
    yavg = (sumy.to_f / total).round 
    center_pos = []
    if (cluster.include?([xavg, yavg]) == false)
      distance_to_center = 100
      cluster.each do |x,y|
        xdiff = (xavg - x).abs
        ydiff = (yavg - y).abs
        xdiff_squared = xdiff ** 2
        ydiff_squared = ydiff ** 2
        distance_squared = xdiff_squared + ydiff_squared
        distance = distance_squared ** 0.5
        if distance < distance_to_center
          center_pos = [x,y]
          distance_to_center = distance
        end
      end
    else
      center_pos = [xavg, yavg]
    end
    return center_pos
  end
 
 #returns the standard deviation of each boundary pixel from the center
  def find_boundary_stdev(center, boundary)
    cx, cy = center[0], center[1]
    total = boundary.length
    sum_dist = 0
    all_distances = []
    boundary.each do |bx, by|
      xdiff = (cx.to_f - bx).abs
      ydiff = (cy.to_f - by).abs
      xdiff_squared = xdiff ** 2
      ydiff_squared = ydiff ** 2
      distance_squared = xdiff_squared + ydiff_squared
      distance = (distance_squared ** 0.5)
      all_distances << distance
      sum_dist += distance
    end
    mean_distance = sum_dist / total
  
    variance_sum = 0
    all_distances.each do |d|
      diff = (mean_distance - d)
      v = diff ** 2
      variance_sum += v 
    end
    variance = variance_sum / total
    stdev = variance ** 0.5 
    return stdev 
  end

  #****** Begin Cluster Segmentation Methods ******
  #*** Begin Methods To Find Radi of pixel to cluster boundaries ***
  def north_radius(xy, cluster)
    north_arr = []
    x, y = xy[0], xy[1]
    ny = y - 1
    in_cluster = cluster.include?([x, ny])
    while in_cluster == true
    	north_arr << [x, ny]
    	ny -= 1
    	in_cluster = false unless cluster.include?([x, ny])
    end
    radius = north_arr.length
    return radius 
  end
  
  def south_radius(xy, cluster)
    south_arr = []
    x, y = xy[0], xy[1]
    sy = y + 1
    in_cluster = cluster.include?([x, sy])
    while in_cluster == true
    	south_arr << [x, sy]
    	sy += 1
    	in_cluster = false unless cluster.include?([x, sy])
    end
    radius = south_arr.length
    return radius 
  end
  
  def east_radius(xy, cluster)
    east_arr = []
    x, y = xy[0], xy[1]
    ex = x + 1
    in_cluster = cluster.include?([ex, y])
    while in_cluster == true
    	east_arr << [ex, y]
    	ex += 1
    	in_cluster = false unless cluster.include?([ex, y])
    end
    radius = east_arr.length
    return radius 
  end
  
  def west_radius(xy, cluster)
    west_arr = []
    x, y = xy[0], xy[1]
    wx = x - 1
    in_cluster = cluster.include?([wx, y])
    while in_cluster == true
    	west_arr << [wx, y]
    	wx -= 1
    	in_cluster = false unless cluster.include?([wx, y])
    end
    radius = west_arr.length
    return radius 
  end
  
  def ne_radius(xy, cluster)
    ne_arr = []
    x, y = xy[0], xy[1]
    nex = x + 1
    ney = y - 1
    in_cluster = cluster.include?([nex, ney])
    while in_cluster == true
    	ne_arr << [nex, ney]
    	nex += 1; ney -= 1
    	in_cluster = false unless cluster.include?([nex, ney])
    end
    radius = ne_arr.length 
    return radius 
  end
  
  def nw_radius(xy, cluster)
    nw_arr = []
    x, y = xy[0], xy[1]
    nwx = x - 1
    nwy = y - 1
    in_cluster = cluster.include?([nwx, nwy])
    while in_cluster == true
    	nw_arr << [nwx, nwy]
    	nwx -= 1; nwy -= 1
    	in_cluster = false unless cluster.include?([nwx, nwy])
    end
    radius = nw_arr.length 
    return radius 
  end
  
  def se_radius(xy, cluster)
    se_arr = []
    x, y = xy[0], xy[1]
    sex = x + 1
    sey = y + 1
    in_cluster = cluster.include?([sex, sey])
    while in_cluster == true
    	se_arr << [sex, sey]
    	sex += 1; sey += 1
    	in_cluster = false unless cluster.include?([sex, sey])
    end
    radius = se_arr.length 
    return radius 
  end
  
  def sw_radius(xy, cluster)
    sw_arr = []
    x, y = xy[0], xy[1]
    swx = x - 1
    swy = y + 1
    in_cluster = cluster.include?([swx, swy])
    while in_cluster == true
    	sw_arr << [swx, swy]
    	swx -= 1; swy += 1
    	in_cluster = false unless cluster.include?([swx, swy])
    end
    radius = sw_arr.length 
    return radius 
  end
  
  #finds the vertical, horizontal, and diagonal radi
  def find_radi(xy, cluster)
    north = north_radius(xy, cluster)
    south = south_radius(xy, cluster)
    east = east_radius(xy, cluster)
    west = west_radius(xy, cluster)
    ne = ne_radius(xy, cluster)
    nw = nw_radius(xy, cluster)
    se = se_radius(xy, cluster)
    sw = sw_radius(xy, cluster)

    all = [north, south, east, west, ne, nw, se, sw]
    return all
  end
  #*** End Methods To Find Radi of pixel to cluster boundaries ***
  
  #redistribute remaining cluster pixels to the two segments 
  def redistribute_to_segments(seg_one, scpos_one, seg_two, scpos_two, remaining_cluster)
    #scpos is short for 'segment center position'
    sc1x, sc1y = scpos_one[0], scpos_one[1]
    sc2x, sc2y = scpos_two[0], scpos_two[1]

    first_seg = seg_one
    second_seg = seg_two
    remaining_cluster.each do |x,y|
      s1_xdiff_sq = (sc1x - x) ** 2
      s1_ydiff_sq = (sc1y - y) ** 2
      s1_sq_sum = s1_xdiff_sq + s1_ydiff_sq
      s1_distance = s1_sq_sum ** 0.5

      s2_xdiff_sq = (sc2x - x) ** 2
      s2_ydiff_sq = (sc2y - y) ** 2
      s2_sq_sum = s2_xdiff_sq + s2_ydiff_sq
      s2_distance = s2_sq_sum ** 0.5
      
      if s1_distance < s2_distance
        first_seg << [x,y]
      elsif s2_distance < s1_distance
      	second_seg << [x,y]
      else #if their distances are equal, send to the smaller of the two segments
      	if first_seg.length < second_seg.length 
      	  first_seg << [x,y]
      	else
      	  second_seg << [x,y]
      	end
      end
    end
    segments = [first_seg, second_seg]
    return segments 	
  end

  def segment_around_radius(xy, radius, cluster)
    segment = []
    x, y = xy[0], xy[1]
    
    cluster.each do |cx,cy|
      xdiff_squared = (cx - x) ** 2
      ydiff_squared = (cy - y) ** 2
      squared_sum = xdiff_squared + ydiff_squared
      distance = squared_sum ** 0.5
      segment << [cx,cy] if distance <= radius
    end
  
    return segment
  end
  
  #returns the pixel posiiton with the greatest minimum radius to the boundary
  #if more than one pixel pos shares the same greates min, the one with the greatest avg radius is used
  def max_min_radius(cluster)
    max_min_pos = []
    max_min_length = 0
    avg_length = 0
    cluster.each do |xy|
      all_radi = find_radi(xy, cluster)
      sum = 0
      all_radi.each {|r| sum += r}
      avg_radius = sum.to_f / 6
      min_radius = all_radi.min
      if min_radius > max_min_length
    	max_min_pos = xy
        max_min_length = min_radius
    	avg_length = avg_radius
      elsif min_radius == max_min_length && avg_radius > avg_length
    	max_min_pos = xy
    	max_min_length = min_radius
    	avg_length = avg_radius
      end
    end
    results = [max_min_pos, max_min_length]
    return results 
  end

  def segment_cluster(cluster)
    
    max_min_attributes = max_min_radius(cluster)
    radius_pos = max_min_attributes[0]
    radius = max_min_attributes[1]

    seg_one = segment_around_radius(radius_pos, radius, cluster)
    
    working_cluster = cluster - seg_one
    working_max_min_attributes = max_min_radius(working_cluster)
    working_radius_pos = working_max_min_attributes[0]
    working_radius = working_max_min_attributes[1]

    seg_two = segment_around_radius(working_radius_pos, working_radius, working_cluster)
  
    remaining_cluster = working_cluster - seg_two

    segments = redistribute_to_segments(seg_one, radius_pos, seg_two, working_radius_pos, remaining_cluster)
  
    return segments 
  end

  #****** End Cluster Segmentation Methods ******

  #*** Begin Maxima Segmentation Methods *** 
  def boundary_stdev_below_threshold?(cluster, threshold)
    center = find_center(cluster)
    boundary = find_boundary(cluster)
    boundary_stdev = find_boundary_stdev(center, boundary)
    
    below_threshold = boundary_stdev <= threshold ? true : false
    return below_threshold
  end
  
  #unique_levels hash must be adjusted to account for the new, segmented maxima levels
  def redistribute_unique_levels(unique_levels, unique_key, unique_levels_after, iterated_levels)
    redistributed_levels = {}
    ukey = unique_key
    unique_levels_after.each {|key, level| redistributed_levels[key] = level}

    unique_levels.each do |key, level|
      next if iterated_levels[key] != nil 
      ukey += 1
      redistributed_levels[ukey] = level 
    end
    return redistributed_levels
  end
  
  #returns a hash where each key is a pixel position with value equal
  #to the unique_level-key it resides in
  def find_pixels_by_levels(redistributed_levels)
    pixels_by_level = {}
    redistributed_levels.each do |lkey, level|
      level.each {|pos| pixels_by_level[pos] = lkey}
    end
    return pixels_by_level
  end

  
  def segment_maximas(level_maximas, unique_levels)
  	#unique_levels is a hash where values are an array of touching pixel positions that share the same level of brightness
  	#level_maximas is a hash of local level maximas keys, with values equalling their associated unique_level key
    maximas_after_segmenting = {}
    max_seg_key = 0
    unique_levels_after = {}
    unique_key = 0
    iterated_levels = {}
    
    level_maximas.each_value do |level_key|
      iterated_levels[level_key] = level_key
      current_level = unique_levels[level_key]
      if current_level.length < SIZE_THRESH
        unique_key += 1
        unique_levels_after[unique_key] = current_level
        max_seg_key += 1
        maximas_after_segmenting[max_seg_key] = unique_key
      elsif boundary_stdev_below_threshold?(current_level, HARD_STDEV) == true
        
        unique_key += 1
        unique_levels_after[unique_key] = current_level
        max_seg_key += 1
        maximas_after_segmenting[max_seg_key] = unique_key
      else
       
        segments = segment_cluster(current_level)
        seg_one = segments[0]
        seg_two = segments[1]

        #check segs to see if further segmenting is needed
        if seg_one.length > SIZE_THRESH && (boundary_stdev_below_threshold?(seg_one, SOFT_STDEV) == false)
          seg_one_segments = segment_cluster(seg_one)
          seg_one_index = segments.index(seg_one)
          segments.delete_at(seg_one_index)
          seg_one_segments.each {|seg| segments << seg}
          seg_one_segments.each {|seg| $seg_segments << seg}
        end
        if seg_two.length > SIZE_THRESH && (boundary_stdev_below_threshold?(seg_two, SOFT_STDEV) == false)
          seg_two_segments = segment_cluster(seg_two)
          seg_two_index = segments.index(seg_two)
          segments.delete_at(seg_two_index)
          seg_two_segments.each {|seg| segments << seg}
          seg_two_segments.each {|seg| $seg_segments << seg}
        end
        segments.each do |seg|
          unique_key += 1
          unique_levels_after[unique_key] = seg 
          max_seg_key += 1
          maximas_after_segmenting[max_seg_key] = unique_key
        end
      end
    end
    
    redistributed_unique_levels = redistribute_unique_levels(unique_levels, unique_key, unique_levels_after, iterated_levels)
    pixels_by_level = find_pixels_by_levels(redistributed_unique_levels)
    after_segmenting = [maximas_after_segmenting, redistributed_unique_levels, pixels_by_level]
    return after_segmenting
  end
  #*** End Maxima Segmentation Methods ***


end