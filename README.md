# DUPLO-Compatible Marble Run Track Generator

Parametric OpenSCAD generator for 3D-printable marble run tracks that snap together using DUPLO-compatible attachment features.

## Features

- **Straight and curved (90°) track pieces**
- **DUPLO-compatible base**: Snap onto DUPLO bricks or connect pieces together using 32mm cavity grid
- **Parametric design**: Adjust width, length, thickness, slope, and rim height
- **Axis-aligned grid**: Duplo cavities always align with global X/Y axes for reliable connections

## Parameters

### Straight Piece Parameters
- `length_studs`: Length of straight track in studs (16mm each, auto-snapped to 2-stud grid)

### Curved Piece Parameters
- `inner_radius_studs`: Inner radius of curved track in studs (16mm each)
- `turn_angle_deg`: Turn angle in degrees (0 = straight, 90 = left turn, -90 or 270 = right turn)

### Common Parameters
- `start_width_studs`: Track width at entry in studs (auto-snapped to 2-stud grid)
- `end_width_studs`: Track width at exit in studs (auto-snapped to 2-stud grid)
- `thickness_mm`: Base thickness in mm
- `rim_thickness_mm`: Side rim thickness in mm
- `rim_height_mm`: Side rim height in mm
- `slope_stud`: Height change per stud length (creates incline/decline)
- `rim_left`, `rim_right`, `rim_front`, `rim_back`: Enable/disable individual rims

## Units

All dimensions use **studs** as the primary unit:
- **1 stud = 16mm** (LEGO/DUPLO stud spacing)
- **1 cavity = 2 studs = 32mm** (DUPLO cavity spacing)

## DUPLO Compatibility

The generator creates attachment features on the bottom of each piece:
- **Rectangular cavity frames** (32mm × 32mm)
- **Center tubes** for secure snapping
- **Automatic grid alignment**: Cavities are positioned on a 32mm lattice and clipped to the piece footprint

### Grid Alignment
- Duplo cavities align with **global X/Y axes** (0°, 90°, 180°, 270°)
- Grid is **origin-anchored** and extends symmetrically in all directions
- Pieces can be rotated, but cavities remain axis-aligned for consistent connections

## Usage

1. Open `code.scad` in OpenSCAD
2. Adjust parameters at the top of the file
3. Press **F5** to preview
4. Press **F6** to render (may take several seconds for curved pieces)
5. Export as STL: **File → Export → Export as STL...**

### Example Configurations

**Simple straight track:**
```scad
length_studs = 16;
start_width_studs = 8;
end_width_studs = 8;
turn_angle_deg = 0;
```

**Left turn (90°):**
```scad
inner_radius_studs = 5;
start_width_studs = 8;
end_width_studs = 8;
turn_angle_deg = 90;
```

**Sloped track:**
```scad
length_studs = 16;
slope_stud = 1;  // 1 stud height drop over length
```

## Design Notes

### Curved Pieces
- Inner radius is set directly from `inner_radius_studs` (no grid snapping)
- Width is taken from max of start/end width (respecting your input)
- Rmid (center radius) = inner_r + width/2
- Arc length = Rmid × angle (in radians)
- DUPLO grid is generated large enough to cover the piece, then clipped to the arc sector

### Grid Coverage
The generator:
1. Calculates piece bounding box (including mid-angle extrema for curves)
2. Creates symmetric grid from origin: `[-max_x, +max_x] × [-max_y, +max_y]`
3. Snaps grid bounds to 32mm lattice
4. Clips cavities to piece footprint using intersection

## Technical Details

- **Coordinate system**: Origin at piece center, rotated pieces maintain axis-aligned grid
- **Render quality**: 
  - Straight pieces: 96 facets (`$fn`)
  - Curved pieces: 192 facets, 160 segments
- **DUPLO dimensions**:
  - Stud diameter: 9.6mm
  - Tube outer: 13.0mm
  - Tube inner: 10.0mm
  - Tube height: 4.8mm
  - Cavity: 32mm × 32mm × 5mm depth

## Printing Tips

- **Layer height**: 0.2mm recommended
- **Infill**: 15-20% for structural pieces
- **Support**: Usually not needed (design is print-friendly)
- **Material**: PLA or PETG work well
- **Post-processing**: Light sanding of cavity edges improves fit

## License

This project is open source. Feel free to modify and share!

## Version

Current version implements:
- Straight and 90° curved pieces
- Parametric width, thickness, slope
- DUPLO-compatible attachment grid
- Axis-aligned cavity placement
- Simplified geometry calculations
