// Straight piece parameters
length_studs = 16;  // Length in studs (16mm each)

// Curved piece parameters  
inner_radius_cavities = 8;  // Arc length in cavity units (32mm each) - controls front/back connection points

// Common parameters
start_width_studs = 8;
end_width_studs   = 8;
thickness_mm = 6.2;
rim_thickness_mm = 1.6;
rim_height_mm = 10.0;
slope_stud = 0;
turn_angle_deg = 0;

rim_left  = true;
rim_right = true;
rim_front = false;
rim_back  = false;

function PITCH()       = 16;
function MIN_THICK()   = 0.8;
function FN_STRAIGHT() = 96;
function FN_CURVED()   = 192;
function CURVE_SEGS()  = 160;

// Duplo compatibility parameters
function DUPLO_STUD_DIAMETER() = 9.6;
function DUPLO_TUBE_OUTER()    = 13.0;
function DUPLO_TUBE_INNER()    = 10.0;
function DUPLO_TUBE_HEIGHT()   = 4.8;
function DUPLO_BOX_SIZE()      = 32.0;  // Exactly 2x2 studs (16mm * 2)
function DUPLO_BOX_DEPTH()     = 5.0;

// Snap dimensions to 2-stud (32mm) grid for Duplo compatibility
function snap_to_duplo_grid(studs) = ceil(studs / 2) * 2;

// Normalise turn input to one of the supported modes: straight, left (+90°), right (-90°)
turn_angle_norm = (turn_angle_deg % 360 + 360) % 360;
turn_dir = (turn_angle_norm < 1e-6 || abs(turn_angle_norm - 360) < 1e-6) ? 0 :
           (abs(turn_angle_norm - 90)  < 1e-6) ?  1 :
           (abs(turn_angle_norm - 270) < 1e-6) ? -1 :
           (turn_angle_deg > 0 ? 1 : -1);

is_straight = (turn_dir == 0);
ang_deg      = turn_dir * 90;
ang_rad      = is_straight ? 0 : ang_deg * PI/180;

cavity_pitch_mm = DUPLO_BOX_SIZE();

// Straight pieces: use length_studs (snapped to 2-stud grid)
length_studs_snapped = snap_to_duplo_grid(length_studs);

// Curved pieces: use inner_radius_cavities (in cavity/32mm units)
inner_radius_cavities_snapped = max(1, round(inner_radius_cavities));

// Width - will be overridden for curved pieces to ensure grid alignment
W0_input = snap_to_duplo_grid(start_width_studs) * PITCH();
W1_input = snap_to_duplo_grid(end_width_studs)   * PITCH();

DROP = slope_stud * PITCH();
T0   = max(thickness_mm, MIN_THICK());
T1   = T0 + DROP;

// Calculate geometry based on piece type
// For curved pieces: back edge must align with cavity grid for Duplo compatibility
// The back edge is at angle ±aabs/2, spanning from inner_r to outer_r
// We need to find Rmid such that back edge corners land on 32mm grid intersections

// Start with target arc length as a reference
arc_length_target = is_straight ? 0 : (inner_radius_cavities_snapped * cavity_pitch_mm);
Rmid_initial = is_straight ? 0 : (arc_length_target / abs(ang_rad));

// For curved: calculate grid-aligned geometry
// At 45° angle, for perfect grid alignment:
// 1. Inner radius = k × 32√2 (so Y-coord is multiple of 32)
// 2. Rmid = n × 32 (so X-coord is multiple of 32)
// 3. Width derived from these: width = 2×(Rmid - inner_r)
sqrt2 = sqrt(2);

// Step 1: Inner radius aligned to diagonal grid  
// inner_r = k × 32√2 for some integer k
inner_r_grid_aligned = round((Rmid_initial - max(W0_input, W1_input)/2) / (cavity_pitch_mm * sqrt2)) * (cavity_pitch_mm * sqrt2);

// Step 2: Outer radius ALSO aligned to diagonal grid
// outer_r = m × 32√2 for some integer m > k
// Start with input width to estimate, then snap
outer_r_estimated = inner_r_grid_aligned + max(W0_input, W1_input);
outer_r_grid_aligned = round(outer_r_estimated / (cavity_pitch_mm * sqrt2)) * (cavity_pitch_mm * sqrt2);

// Step 3: Initial width from aligned radii
width_initial = outer_r_grid_aligned - inner_r_grid_aligned;

// Step 4: Snap both inner and outer radii to diagonal grid
// This ensures both are k × 32√2
// Keep width as close to input as possible while maintaining grid alignment
width_grid_aligned = outer_r_grid_aligned - inner_r_grid_aligned;

// Step 5: Rmid from snapped radii
Rmid_grid_aligned = inner_r_grid_aligned + width_grid_aligned / 2;

// Final values
Rmid = is_straight ? 0 : Rmid_grid_aligned;
W0 = is_straight ? W0_input : width_grid_aligned;
W1 = is_straight ? W1_input : width_grid_aligned;

// L is the actual length (straight) or arc length (curved)
L = is_straight ? (length_studs_snapped * PITCH())
                : (Rmid * abs(ang_rad));

module build(){
  echo("Turn mode =", is_straight ? "straight" : (turn_dir > 0 ? "left" : "right"), " (deg =", ang_deg, ")");
  if (is_straight)
    echo("Straight length (studs, mm) =", length_studs, "→", length_studs_snapped, "studs,", L, "mm");
  else {
    echo("Curved target arc length =", inner_radius_cavities, "→", inner_radius_cavities_snapped, "×32 =", arc_length_target, "mm");
    echo("Rmid (grid-aligned) =", Rmid_initial, "→", Rmid, "mm, Arc length =", L, "mm");
    echo("Inner radius =", inner_r_grid_aligned, "mm, Width (grid-aligned) =", width_grid_aligned, "mm");
  }
  if (is_straight)
    echo("W0/W1 (stud, mm) =", start_width_studs, "→", snap_to_duplo_grid(start_width_studs), "/", end_width_studs, "→", snap_to_duplo_grid(end_width_studs), "studs,", W0, "/", W1, "mm");
  echo("thickness entry/exit (mm) =", T0, "/", T1, "  slope (stud, mm) =", slope_stud, "/", DROP);
  if (is_straight) straight_piece();
  else             curved_piece_centered();
}
build();

module straight_piece(){
  $fn = FN_STRAIGHT();

  union(){
    hull(){
      translate([0, -L/2 + 0.01, 0])
        linear_extrude(height=T0)
          rect2d(W0, 0.02);
      translate([0,  L/2 - 0.01, 0])
        linear_extrude(height=T1)
          rect2d(W1, 0.02);
    }

    if (rim_height_mm > 0 && rim_thickness_mm > 0){
      if (rim_left)
        hull(){
          translate([-W0/2, -L/2 + 0.01, T0])
            cube([rim_thickness_mm, 0.01, rim_height_mm], center=false);
          translate([-W1/2,  L/2 - 0.01, T1])
            cube([rim_thickness_mm, 0.01, rim_height_mm], center=false);
        }
      if (rim_right)
        hull(){
          translate([ W0/2 - rim_thickness_mm, -L/2 + 0.01, T0])
            cube([rim_thickness_mm, 0.01, rim_height_mm], center=false);
          translate([ W1/2 - rim_thickness_mm,  L/2 - 0.01, T1])
            cube([rim_thickness_mm, 0.01, rim_height_mm], center=false);
        }
      if (rim_front)
        translate([-W0/2, -L/2, T0])
          cube([W0, rim_thickness_mm, rim_height_mm], center=false);
      if (rim_back)
        translate([-W1/2,  L/2 - rim_thickness_mm, T1])
          cube([W1, rim_thickness_mm, rim_height_mm], center=false);
    }
    
    // Add Duplo attachment features on bottom
    duplo_attachment_features(max(W0, W1), L, 0);
  }
}

module rect2d(w, l){ translate([-w/2, -l/2]) square([w, l], center=false); }

module duplo_single_attachment(){
  // Creates one Duplo attachment: rectangular frame + center tube
  wall_thickness = 1.5;
  
  // Outer rectangular frame/walls
  difference(){
    translate([-DUPLO_BOX_SIZE()/2, -DUPLO_BOX_SIZE()/2, -DUPLO_BOX_DEPTH()])
      cube([DUPLO_BOX_SIZE(), DUPLO_BOX_SIZE(), DUPLO_BOX_DEPTH()], center=false);
    // Hollow out the inside (leave walls)
    translate([-(DUPLO_BOX_SIZE()-2*wall_thickness)/2, -(DUPLO_BOX_SIZE()-2*wall_thickness)/2, -DUPLO_BOX_DEPTH()-0.1])
      cube([DUPLO_BOX_SIZE()-2*wall_thickness, DUPLO_BOX_SIZE()-2*wall_thickness, DUPLO_BOX_DEPTH()+0.2], center=false);
  }
  
  // Center tube (hollow cylinder)
  translate([0, 0, -DUPLO_TUBE_HEIGHT()])
    difference(){
      cylinder(h=DUPLO_TUBE_HEIGHT(), d=DUPLO_TUBE_OUTER(), center=false, $fn=32);
      translate([0, 0, -0.1])
        cylinder(h=DUPLO_TUBE_HEIGHT() + 0.2, d=DUPLO_TUBE_INNER(), center=false, $fn=32);
    }
}

module duplo_attachment_features(width, length, z_base, offset_x=0, offset_y=0, x_min=undef, y_min=undef){
  // Duplo cavities are on 2x2 stud grid (32mm spacing)
  cavity_pitch = 2 * PITCH();
  
  // If bounds are provided, place cavities at exact lattice points
  // Otherwise use the legacy centered approach
  if (x_min != undef && y_min != undef) {
    // Place cavities at lattice points within [x_min, x_min+width] × [y_min, y_min+length]
    x_start = x_min + cavity_pitch/2;
    y_start = y_min + cavity_pitch/2;
    cavities_x = floor(width / cavity_pitch);
    cavities_y = floor(length / cavity_pitch);
    
    for (ix = [0:cavities_x-1])
      for (iy = [0:cavities_y-1]){
        x_pos = x_start + ix * cavity_pitch;
        y_pos = y_start + iy * cavity_pitch;
        translate([x_pos, y_pos, z_base])
          duplo_single_attachment();
      }
  } else {
    // Legacy: center the grid
    cavities_x = floor(width / cavity_pitch);
    cavities_y = floor(length / cavity_pitch);
    
    for (ix = [0:cavities_x-1])
      for (iy = [0:cavities_y-1]){
        x_pos = (ix - (cavities_x-1)/2) * cavity_pitch + offset_x;
        y_pos = (iy - (cavities_y-1)/2) * cavity_pitch + offset_y;
        translate([x_pos, y_pos, z_base])
          duplo_single_attachment();
      }
  }
}

module curved_piece_centered(){
  $fn = FN_CURVED();
  aabs = abs(ang_deg);

  rotate([0,0,-ang_deg/2])
    translate([-Rmid, 0, 0]){
      
      union(){
        // Main track body
        for (i = [0:CURVE_SEGS()-1]){
          t   = (i + 0.5) / CURVE_SEGS();
          a0  = (-aabs/2) + (i    / CURVE_SEGS()) * aabs;
          a1  = (-aabs/2) + ((i+1)/ CURVE_SEGS()) * aabs;
          t_top = T0 + (T1 - T0) * t;
          w_mid = W0 + (W1 - W0) * t;
          if (t_top > 0 && w_mid > 0){
            Rin_s = Rmid - w_mid/2;
            rotate([0,0,a0])
              rotate_extrude(angle=(a1 - a0))
                translate([Rin_s,0,0])
                  square([w_mid, t_top], center=false);
          }
        }

        // Rims
        if (rim_height_mm > 0 && rim_thickness_mm > 0){
          if (rim_left || rim_right)
            for (i = [0:CURVE_SEGS()-1]){
              t   = (i + 0.5) / CURVE_SEGS();
              a0  = (-aabs/2) + (i    / CURVE_SEGS()) * aabs;
              a1  = (-aabs/2) + ((i+1)/ CURVE_SEGS()) * aabs;
              t_top = T0 + (T1 - T0) * t;
              w_mid = W0 + (W1 - W0) * t;
              if (t_top > 0 && w_mid > 0){
                Rin_s = Rmid - w_mid/2;
                Rout_s= Rmid + w_mid/2;
                if (rim_left)
                  rotate([0,0,a0])
                    translate([0,0,t_top])
                      rotate_extrude(angle=(a1 - a0))
                        translate([Rin_s,0,0])
                          square([rim_thickness_mm, rim_height_mm], center=false);
                if (rim_right)
                  rotate([0,0,a0])
                    translate([0,0,t_top])
                      rotate_extrude(angle=(a1 - a0))
                        translate([Rout_s - rim_thickness_mm,0,0])
                          square([rim_thickness_mm, rim_height_mm], center=false);
              }
            }

          d_ang = (Rmid > 0) ? (rim_thickness_mm / Rmid) * 180/PI : 0;
          if (rim_front && d_ang > 0){
            rotate([0,0,-aabs/2])
              translate([0,0,T0])
                rotate_extrude(angle=d_ang)
                  translate([Rmid - W0/2,0,0])
                    square([W0, rim_height_mm], center=false);
          }
          if (rim_back && d_ang > 0){
            rotate([0,0, aabs/2 - d_ang])
              translate([0,0,T1])
                rotate_extrude(angle=d_ang)
                  translate([Rmid - W1/2,0,0])
                    square([W1, rim_height_mm], center=false);
          }
        }
        
        // Add Duplo features, clipped to piece footprint
        intersection(){
          // Duplo features - counter-rotate to align with global axes
          rotate([0,0,ang_deg/2])
            union(){
              cavity_pitch = DUPLO_BOX_SIZE();
            arc_length = aabs * PI/180 * Rmid;
            inner_r = Rmid - max(W0, W1)/2;
            outer_r = Rmid + max(W0, W1)/2;
            
            // Grid dimensions need to cover the full bounding box of the rotated piece
            // Calculate bounding box size first, then snap to cavity pitch
            
            // Temporary calculation of piece bounds to determine grid size
            angle_start_temp = -aabs/2;
            angle_end_temp = aabs/2;
            
            echo("Curved piece: Rmid=", Rmid, " inner_r=", inner_r, " arc_length=", arc_length);
            
            // Calculate actual piece corner positions
            // Grid is counter-rotated to align with global axes
            // In grid frame: piece spans from 0° to aabs (e.g., 0° to 90° for left turn)
            angle_start = 0;        // Front edge (globally aligned)
            angle_end = aabs;       // Back edge
            
            // Four corners of the arc sector
            // In this local frame (after translate([-Rmid, 0, 0])), 
            // the arc center is at (Rmid, 0, 0)
            // Corner 1: inner radius, front edge
            piece_corner1_x = Rmid + inner_r * cos(angle_start);
            piece_corner1_y = inner_r * sin(angle_start);
            
            // Corner 2: outer radius, front edge  
            piece_corner2_x = Rmid + outer_r * cos(angle_start);
            piece_corner2_y = outer_r * sin(angle_start);
            
            // Corner 3: inner radius, back edge
            piece_corner3_x = Rmid + inner_r * cos(angle_end);
            piece_corner3_y = inner_r * sin(angle_end);
            
            // Corner 4: outer radius, back edge
            piece_corner4_x = Rmid + outer_r * cos(angle_end);
            piece_corner4_y = outer_r * sin(angle_end);
            
            // Robust bounding box of the arc sector (includes mid-angle extremes)
            theta_min = angle_start;  // 0°
            theta_max = angle_end;    // aabs (e.g., 90°)
            
            // For 0° to 90°: X max is at 0° (Rmid + outer_r), Y max is at 90° (outer_r)
            // X extents (arc centered at Rmid in local frame)
            x_max_at_zero = (theta_min <= 0 && theta_max >= 0) ? (Rmid + outer_r) : -1e9;
            x_min_candidates = [
              Rmid + inner_r * cos(theta_min),
              Rmid + inner_r * cos(theta_max)
            ];
            piece_x_min = min(x_min_candidates);
            
            x_max_candidates = [
              Rmid + outer_r * cos(theta_min),
              Rmid + outer_r * cos(theta_max),
              x_max_at_zero
            ];
            piece_x_max = max(x_max_candidates);
            
            // Y extents (on outer radius)
            y_max_at_90 = (theta_min <= 90 && theta_max >= 90) ? outer_r : -1e9;
            y_candidates = [
              outer_r * sin(theta_min),
              outer_r * sin(theta_max),
              y_max_at_90
            ];
            piece_y_min = min(y_candidates);
            piece_y_max = max(y_candidates);
            
            // Origin-anchored symmetric grid snapped to 32mm lattice
            half_x = ceil(max(abs(piece_x_min), abs(piece_x_max)) / cavity_pitch) * cavity_pitch;
            half_y = ceil(max(abs(piece_y_min), abs(piece_y_max)) / cavity_pitch) * cavity_pitch;

            grid_x_min = -half_x;
            grid_x_max =  half_x;
            grid_y_min = -half_y;
            grid_y_max =  half_y;

            grid_w = grid_x_max - grid_x_min; // = 2*half_x
            grid_l = grid_y_max - grid_y_min; // = 2*half_y

            cols = grid_w / cavity_pitch;
            rows = grid_l / cavity_pitch;

            // Anchor grid at origin
            offset_x = 0;
            offset_y = 0;

            echo("Grid dimensions: cols=", cols, " rows=", rows, " → ", grid_w, "×", grid_l, "mm");
            echo("Grid  X: ", grid_x_min, " to ", grid_x_max, " (width=", grid_w, ")");
            echo("Grid  Y: ", grid_y_min, " to ", grid_y_max, " (length=", grid_l, ")");
            
            echo("=== Piece Corners (in grid coords) ===");
            echo("Corner 1 (inner,front): (", piece_corner1_x, ", ", piece_corner1_y, ")");
            echo("Corner 2 (outer,front): (", piece_corner2_x, ", ", piece_corner2_y, ")");
            echo("Corner 3 (inner,back):  (", piece_corner3_x, ", ", piece_corner3_y, ")");
            echo("Corner 4 (outer,back):  (", piece_corner4_x, ", ", piece_corner4_y, ")");
            echo("=== Alignment Check ===");
            echo("Piece X: ", piece_x_min, " to ", piece_x_max, " (width=", piece_x_max - piece_x_min, ")");
            echo("Grid  X: ", grid_x_min, " to ", grid_x_max, " (width=", grid_x_max - grid_x_min, ")");
            echo("X diff: start=", grid_x_min - piece_x_min, " end=", grid_x_max - piece_x_max);
            echo("Piece Y: ", piece_y_min, " to ", piece_y_max, " (length=", piece_y_max - piece_y_min, ")");
            echo("Grid  Y: ", grid_y_min, " to ", grid_y_max, " (length=", grid_y_max - grid_y_min, ")");
            echo("Y diff: start=", grid_y_min - piece_y_min, " end=", grid_y_max - piece_y_max);
            
            duplo_attachment_features(grid_w, grid_l, 0, offset_x, offset_y, grid_x_min, grid_y_min);
          }
          
          // Bounding volume: arc sector matching piece footprint (piece frame)
          // Arc spans from -aabs/2 to +aabs/2 in this frame
          rotate([0,0,-aabs/2])
            translate([0, 0, -20])
              rotate_extrude(angle=aabs)
                translate([Rmid - max(W0, W1)/2, 0, 0])
                  square([max(W0, W1), 20.1], center=false);
        }
      }
    }
}