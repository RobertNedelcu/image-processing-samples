
module Drawing

  #********Begin Methods To Find MyBez Points************

  #***general helper methods

  #find avg_val from an array of vals
  def array_avg(arr)
    sum = 0
    arr.each {|v| sum += v} 
    avg = sum.to_f / arr.length
    return avg 
  end

  #center points are floating and do not have to be in the blob
  def find_noninclusive_center(blob) 
    sumx = 0; sumy = 0
    total = blob.length
    blob.each do |x,y|
      sumx += x 
      sumy += y
    end
    xavg = sumx.to_f / total
    yavg = sumy.to_f / total 
    center_pos = [xavg, yavg]
    return center_pos
  end
  #***end general helper methods

  #***begin methods for solving the equation of a line

  def solve_slope(p1, p2)
    p1x, p1y = p1[0], p1[1]
    p2x, p2y = p2[0], p2[1]
    #if change in x = 0 (AKA vertical line), slope = 0 instead of NaN
    slope = (p1x - p2x) != 0 ? (p1y - p2y).to_f / (p1x - p2x) : 0.0  
    return slope 
  end
  
  def solve_b(m, point)
    x, y = point[0], point[1]
    b = y - (m * x)
    return b 
  end

  def solve_y(x, m, b)
    y = (m * x) + b
    return y 
  end
  
  def solve_x(y, m, b)
    x = (y - b) / m
    return x 
  end

  def find_line(area, p1, p2, set_x_or_y)
    x_or_y_lines = {}
    
    area.each do |x,y|
      if set_x_or_y == 'y'
        x_or_y_lines[y] ||= []
        x_or_y_lines[y] << [x,y]
      else
        x_or_y_lines[x] ||= []
        x_or_y_lines[x] << [x,y]
      end
    end
  
    line = {}
    slope = solve_slope(p1, p2)
    b = solve_b(slope, p2)
    x_or_y_lines.each_key do |x_or_y|
      if set_x_or_y == 'y'
        x = solve_x(x_or_y, slope, b)
        x = p1[0] if slope == 0
        line[x_or_y] = x 
      else
        y = solve_y(x_or_y, slope, b)
        line[x_or_y] = y 
      end
    end
    return line
  end
  #***end equation of line methods

  #***begin segmenting methods

  def segment_by_set_x_or_y(cluster, center, set_x_or_y)
    area_one = []; area_two = []
    cluster.each do |x, y|
      if set_x_or_y == 'y'
        area_one << [x,y] if y < center[1]
        area_two << [x,y] if y > center[1]
      else
        area_one << [x,y] if x < center[0]
        area_two << [x,y] if x > center[0]
      end
    end
    segments = [area_one, area_two]
    return segments
  end

  def segment_by_floating_line(area, line, set_x_or_y)
   seg_one = []; seg_two = []
   area.each do |x,y|
     if set_x_or_y == 'y'
       seg_one << [x,y] if x < line[y]
       seg_two << [x,y] if x > line[y]
     else
      seg_one << [x,y] if y < line[x]
      seg_two << [x,y] if y > line[x]
     end
   end
   segments = [seg_one, seg_two]
   return segments 
  end
  #***end segmenting methods
  
  #***begin handle length and position methods
  def find_handle_length(center, area, set_x_or_y)
    center_val = set_x_or_y == 'y' ? center[1] : center[0]
    max_distance = 0
    actual_distance = 0
    area.each do |x,y|
      if set_x_or_y == 'y'
        distance = y - center_val  
        actual_distance = distance if distance.abs > max_distance
        max_distance = distance.abs if distance.abs > max_distance
      else
        distance = x - center_val 
        actual_distance = distance if distance.abs > max_distance
        max_distance = distance.abs if distance.abs > max_distance
      end
    end
    handle_length = actual_distance * 1.33
    return handle_length
  end

  def find_handle(v, length, slope, set_x_or_y)
    handle_pos = []
    b = solve_b(slope, v)
    if set_x_or_y == 'y'
      y = v[1] + length 
      x = slope == 0 ? v[0] : solve_x(y, slope, b) 
      
      handle_pos = [x.round,y.round]
    else
      x = v[0] + length 
      y = solve_y(x, slope, b)
       
      handle_pos = [x.round,y.round]
    end
    return handle_pos
  end
  #***end handle length and position methods

  #*** methods for finding center line points ****

  #Find the best line, either vertical or horizontal, that most equally divides the blob in two
  def best_center_line(blob)
    vertx_lines = {} #keys are x position in blob, values are an array of all y values at pos x
    horzy_lines = {} #keys are y position in blob, values are an array of all x values at pos y
    blob.each do |x,y|
      vertx_lines[x] ||= []; horzy_lines[y] ||= []
      vertx_lines[x] << y
      horzy_lines[y] << x
    end
    sorted_xs = vertx_lines.keys.sort #sorted array of all x values
    sorted_ys = horzy_lines.keys.sort #sorted array of all y values

    left_count = 0; right_count = blob.length 
    below_count = 0; above_count = blob.length

    left_of = {}; right_of = {} 
    above_of = {}; below_of = {}
    #keys are each [x,y] position and values are the number of
    #pixels in the blob that are to its left, right, below, or above
    sorted_xs.each do |x|
      line = vertx_lines[x]
      right_count -= line.length 
      line.each {|y| left_of[[x,y]] = left_count}
      line.each {|y| right_of[[x,y]] = right_count}
      left_count += line.length 
    end
    sorted_ys.each do |y|
      line = horzy_lines[y]
      above_count -= line.length 
      line.each {|x| below_of[[x,y]] = below_count}
      line.each {|x| above_of[[x,y]] = above_count}
      below_count += line.length 
    end
    
    best_pos = []; min_diff = 1000 #best_pos is the position (in the blob) that most equally divides it
    set_x_or_y = nil #<used to determine if the horizontal or vertical line through best_pos should be used
    blob.each do |pos|
      xdiff = (left_of[pos] - right_of[pos]).abs 
      ydiff = (above_of[pos] - below_of[pos]).abs 
      total_diff = xdiff + ydiff
      if total_diff < min_diff
      	best_pos = pos 
      	min_diff = total_diff
      	set_x_or_y = xdiff < ydiff ? 'x' : 'y' 
      end
    end

    best_line = set_x_or_y == 'x' ? vertx_lines[best_pos[0]] : horzy_lines[best_pos[1]]
    best_line_sorted = best_line.sort 
    best_line_val = set_x_or_y == 'x' ? best_pos[0] : best_pos[1]
    result = [best_line_sorted, best_line_val, set_x_or_y]
    return result
  end

  #finds points for v1, v2, center, and centers between v1/v2 and center of the best dividing line
  def find_center_line_points(blob)
    center_line_points = []
     
    best_line_attributes = best_center_line(blob)
    best_line_sorted = best_line_attributes[0]
    best_line_val = best_line_attributes[1]
    set_x_or_y = best_line_attributes[2]
      
    v1 = []           #vector point one
    v2 = []           #vector point two
    center = []       #center point
    center_v1tc = []  #center point between v1 and center
    center_v2tc = []  #center point between v2 and center
      
    center_avg = array_avg(best_line_sorted)
    if set_x_or_y == 'x'
      vx = best_line_val
      v1y, v2y = best_line_sorted.first, best_line_sorted.last
      v1 = [vx, v1y]
      v2 = [vx, v2y]
      
      center = [vx, center_avg]
      
      center_y_v1tc = (center_avg + v1y) / 2
      center_y_v2tc = (center_avg + v2y) / 2
      center_v1tc = [vx, center_y_v1tc]
      center_v2tc = [vx, center_y_v2tc]
    else
      vy = best_line_val
      v1x, v2x = best_line_sorted.first, best_line_sorted.last
      v1 = [v1x, vy]
      v2 = [v2x, vy]
      
      center = [center_avg, vy]
      
      center_x_v1tc = (center_avg + v1x) / 2
      center_x_v2tc = (center_avg + v2x) / 2
      center_v1tc = [center_x_v1tc, vy]
      center_v2tc = [center_x_v2tc, vy]
    end
    center_line_points = [v1, v2, center, center_v1tc, center_v2tc, set_x_or_y]
    
    return center_line_points
  end
  #***end methods for finding center line points

  def find_mybez_points(blob)
    center_line_points = find_center_line_points(blob)
    
    v1, v2 = center_line_points[0], center_line_points[1]
    center = center_line_points[2]
    center_v1tc, center_v2tc = center_line_points[3], center_line_points[4]     
    set_x_or_y = center_line_points[5]
    
    #divide blob into two areas around center line
    segments = segment_by_set_x_or_y(blob, center, set_x_or_y)
    area_one = segments[0]
    area_two = segments[1]
    
    area_one_center = find_noninclusive_center(area_one)
    area_two_center = find_noninclusive_center(area_two)
    
    area_one_line = find_line(area_one, center, area_one_center, set_x_or_y)
    area_two_line = find_line(area_two, center, area_two_center, set_x_or_y)
    
    #further segments each area
    area_one_segments = segment_by_floating_line(area_one, area_one_line, set_x_or_y)
    area_two_segments = segment_by_floating_line(area_two, area_two_line, set_x_or_y)
    area_one_a, area_one_b = area_one_segments[0], area_one_segments[1]
    area_two_a, area_two_b = area_two_segments[0], area_two_segments[1]
    #prevents error in rare case that a given area is empty
    if area_one_a.empty? && area_one_b.length > 0
    	area_one_a = area_one_b
    elsif area_one_b.empty? && area_one_a.length > 0
    	area_one_b = area_one_a
    end
    if area_two_a.empty? && area_two_b.length > 0
    	area_two_a = area_two_b
    elsif area_two_b.empty? && area_two_a.length > 0
    	area_two_b = area_two_a
    end
    area_one_a = area_one_a.length > 0 ? area_one_a : area_two_a
    area_two_a = area_two_a.length > 0 ? area_two_a : area_one_a
    
    area_1a_center = find_noninclusive_center(area_one_a)
    area_1a_center = v2 if area_1a_center[0].nan?
    area_1b_center = find_noninclusive_center(area_one_b)
    area_1b_center = v1 if area_1b_center[0].nan?
    area_2a_center = find_noninclusive_center(area_two_a)
    area_2a_center = v2 if area_2a_center[0].nan?
    area_2b_center = find_noninclusive_center(area_two_b)
    area_2b_center = v1 if area_2b_center[0].nan?
     
    area_1a_slope = solve_slope(center_v1tc, area_1a_center)
    area_1b_slope = solve_slope(center_v2tc, area_1b_center)
    area_2a_slope = solve_slope(center_v1tc, area_2a_center)
    area_2b_slope = solve_slope(center_v2tc, area_2b_center)
    
    handle_1a_length = find_handle_length(center_v1tc, area_one_a, set_x_or_y)
    handle_1b_length = find_handle_length(center_v2tc, area_one_b, set_x_or_y)
    handle_2a_length = find_handle_length(center_v1tc, area_two_a, set_x_or_y)
    handle_2b_length = find_handle_length(center_v2tc, area_two_b, set_x_or_y)
    
    h1a = find_handle(v1, handle_1a_length, area_1a_slope, set_x_or_y) 
    h1b = find_handle(v2, handle_1b_length, area_1b_slope, set_x_or_y)
    h2a = find_handle(v1, handle_2a_length, area_2a_slope, set_x_or_y)
    h2b = find_handle(v2, handle_2b_length, area_2b_slope, set_x_or_y)
     
    p1 = [v1, h1a, v2, h1b]
    p2 = [v1, h2a, v2, h2b]
     
    points = [p1, p2]
      
    return points 
  end
  #***********End Methods For Finding MyBez Points *************

  #***********Begin Methods For Drawing MyBez Curve ************

  def find_max_line_length(v1, h1, v2, h2)
    #lines 
    v1_h1 = [v1, h1]
    h1_h2 = [h1, h2]
    h2_v2 = [h2, v2]
    lines = [v1_h1, h1_h2, h2_v2]
  
    max_length = 1
    lines.each do |p1, p2|
      p1x, p1y = p1[0], p1[1]
      p2x, p2y = p2[0], p2[1]
      xdist_squared = (p1x - p2x) ** 2
      ydist_squared = (p1y - p2y) ** 2
      squared_sum = xdist_squared + ydist_squared
      distance = squared_sum.to_f ** 0.5
      max_length = distance if distance > max_length
    end
    return max_length
  end

  def mybez_curve(v1, h1, v2, h2)
    curve_points_hash = {}
    curve_points = []
  
    v1x, v1y = v1[0], v1[1]
    h1x, h1y = h1[0], h1[1]
    v2x, v2y = v2[0], v2[1]
    h2x, h2y = h2[0], h2[1]
    
    max_length = find_max_line_length(v1, h1, v2, h2)
    max_curve_length = max_length * 3.2 #(diameter * pie.rounded) = max possible length of curve 
    percent_inc = 1 / max_curve_length  #ensures continuous points of curve are drawn.
    percent_complete = 0                #each component part of the bezier curve - 
    until percent_complete > 1.0        #progresses at the same rate-of-completion.
      start_w = 1.0 - percent_complete  #percent weight that the starting position has on moving point 
      end_w = percent_complete          #percent weight that the end position has on the moving point
      #moving points across vector/handle lines
      point_v1_h1 = [((v1x * start_w)+(h1x * end_w)), ((v1y * start_w)+(h1y * end_w))]
      point_h1_h2 = [((h1x * start_w)+(h2x * end_w)), ((h1y * start_w)+(h2y * end_w))]
      point_h2_v2 = [((h2x * start_w)+(v2x * end_w)), ((h2y * start_w)+(v2y * end_w))]
      #creates the 2 non-base parts of a triangle as it connects points in vector/handle lines
      v1v2_h1h2 = [((point_v1_h1[0] * start_w)+(point_h1_h2[0] * end_w)), ((point_v1_h1[1] * start_w)+(point_h1_h2[1] * end_w))]
      h1h2_h2v2 = [((point_h1_h2[0] * start_w)+(point_h2_v2[0] * end_w)), ((point_h1_h2[1] * start_w)+(point_h2_v2[1] * end_w))]
      #is the base of the ^ triangle. The curve is drawn using the moving point on this moving line
      tangent = [((v1v2_h1h2[0] * start_w)+(h1h2_h2v2[0] * end_w)).round, ((v1v2_h1h2[1] * start_w)+(h1h2_h2v2[1] * end_w)).round]

      if curve_points_hash[tangent] == nil   #checks if the percentage increment yields a new position (rounded)
        curve_points_hash[tangent] = tangent #prevents duplicates from being added to outline
        curve_points << tangent
      end
  
      percent_complete += percent_inc
    end
    
    return curve_points
  end
  #***********End Methods For Drawing MyBez Curve *****************
  
  def create_outline(original_blob)                    
    blob = original_blob.dup                        #since y increases as it progresses downward, invert pixel positions by making all
    blob.map! {|pos| pos = [pos[0], (pos[1] * -1)]} #y vals negative so that points behave as they would on a normal 2D plane 
    points = find_mybez_points(blob)
    
    p1, p2 = points[0], points[1]
    p1.map! {|pos| pos = [pos[0], (pos[1] * -1)]}   #turn y val's back to positive
    p2.map! {|pos| pos = [pos[0], (pos[1] * -1)]}
     
    v1a, h1a = p1[0], p1[1]
    v2a, h2a = p1[2], p1[3]
    
    v1b, h1b = p2[0], p2[1]
    v2b, h2b = p2[2], p2[3]
    
    curve_points_a = mybez_curve(v1a, h1a, v2a, h2a)
    curve_points_b = mybez_curve(v1b, h1b, v2b, h2b)

    oval = curve_points_a.concat(curve_points_b)
    #returns the positions of each pixel in the oval 
    return oval                               
  end

end