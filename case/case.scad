// -----------------------------------------------------------------------------
// --------------- Key Parameters, Fine-Tuning Here ---------------------------
// -----------------------------------------------------------------------------

$fn = 100;

// Dimensions & geometry
// -------------------- Parameters --------------------
jack_height = 5;
jack_hole_diameter = 6;
fillet_radius = 2;
wall_thickness = 0.8;

fr4_thickness = 1.6;

immersion_depth = fr4_thickness;
case_thickness = 4;
solder_gap = 2.2;

pcb_and_plate_thickness = fr4_thickness+case_thickness;

// USB
w_shell = 8.94;
h_shell = 3.26;
r_corner = 1.2;
pcb_usb_distance = 3; // distance of pcb to bottom of usb
Z_USB = h_shell + pcb_usb_distance;
//, 64.72
usb_main_offset = [104.59, 62.81+wall_thickness, Z_USB];
usb_tunnel_offset = [113.45-w_shell/2, 62.81+50, Z_USB];
usb_tunnel_len_mm = 50;

// Single drawing file + layer names
DRAWING = "ferris_sweep_high.svg";
DPI=96;

L_plate = "pcb_outline";
L_hole_markers = "hole_markers";
L_feet_markers = "feet_markers";
L_usb = "controller_cutout";
L_solder = "solder_holes";
L_controller_bottom = "controller_cover_bottom";
L_controller_top = "controller_cover_top";
L_jack_cover = "jack_cover";

// feet positions & sizes
feet_positions = [[91.095, 82.979], [96.882, 5.982], [4.386, 74.434], [4.954, 24.844]];
feet_diameter = 8.0;
feet_marker_diameter = 7.0;
feet_depth = 1.2;

// Screw sizes
case_screw_diameter = 2.9;
screw_marker_diameter = 2.2;

// Clearances
clear_pcb_mm = 0.3;
clear_usb_mm = 0.5;
clear_switch_mm = 0.2;
reset_button_thick = 0.2;

// Derived
Z_LID_BASE = -case_thickness;
total_height_top_case = pcb_and_plate_thickness + immersion_depth;
EXPLODE = 10;

// -----------------------------------------------------------------------------
// --------------------------- Optional Tent Support ---------------------------
// -----------------------------------------------------------------------------
// Render by setting PART = "tent"
// Note: Changing tenting_angle requires adjusting tent_lowering.

// ---- Tenting Parameters ----
tenting_angle = 10;
tent_base_thickness = 1;
tent_support_base_thickness = 0.0001;
tent_support_base_width = 2;
tent_support_wall_thickness = 1.5;
tent_support_wall_height = 6;
tent_clearance = 0.2;
tent_lowering = 0.0;


// -----------------------------------------------------------------------------
// ------------------------------- Helpers -------------------------------------
// -----------------------------------------------------------------------------

// -------------------- Module: extrude_layer --------------------
module extrude_layer(layer, z = 0, h = 1, delta = 0) { translate([0, 0, z]) linear_extrude(height=h) offset(delta=delta) import(file=DRAWING, dpi=DPI, layer=layer); }

// -------------------- Module: drill_holes --------------------
module drill_holes(positions, d, z, h) { for (p = positions) translate([p[0], p[1], z]) cylinder(d=d, h=h); }

// -----------------------------------------------------------------------------
// ------------------------------ Components -----------------------------------
// -----------------------------------------------------------------------------

// -------------------- Module: usb_c_cutout_2d --------------------
module usb_c_cutout_2d(c = 0.1) {
  w = w_shell + 2 * c;
  h = h_shell + 2 * c;
  minkowski() { square([w - 2 * r_corner, h - 2 * r_corner], center=true); circle(r=r_corner, $fn=64); }
}

// -------------------- Module: pcb_stack --------------------
module pcb_stack() { extrude_layer(L_plate, h=actual_bottom_foam_thickness + pcb_and_plate_thickness + immersion_depth + seal_thickness, delta=clear_pcb_mm); }

module pcb() {
    difference() {
    extrude_layer(L_plate, h=fr4_thickness, delta=0);
    pcb_screw_holes();
    }
}

module jack_cutout() { translate([110.85, 26, fr4_thickness+jack_hole_diameter/2]) rotate([0, 90, 0]) cylinder(d=jack_hole_diameter, h=4); }

// -------------------- Module: case_feet_holes --------------------
module case_feet_holes() {
    extrude_layer(L_feet_markers, z=Z_LID_BASE, h=feet_depth, delta=(feet_diameter-feet_marker_diameter)/2); 
    //drill_holes(feet_positions, feet_diameter, Z_LID_BASE, feet_depth);
}

// -------------------- Module: case_screw_holes --------------------
module case_screw_holes() { 
    extrude_layer(L_hole_markers, z=Z_LID_BASE, h=case_thickness, delta=(case_screw_diameter-screw_marker_diameter)/2); 

//drill_holes(screw_positions, case_screw_diameter, Z_LID_BASE,case_thickness); 
}

// -------------------- Module: lid_screw_holes --------------------
module pcb_screw_holes() { 
    extrude_layer(L_hole_markers, h=fr4_thickness, delta=0); 
}
//drill_holes(screw_positions, pcb_screw_diameter, 0, fr4_thickness); }

// -------------------- Module: usb_c_cutout_position --------------------
module usb_c_cutout_position() {
  translate(usb_main_offset) rotate([90, 0, 0]) linear_extrude(height=wall_thickness+0.2) usb_c_cutout_2d(0.1);
  //translate(usb_tunnel_offset) rotate([90, 0, 0]) linear_extrude(height=usb_tunnel_len_mm) usb_c_cutout_2d(1.5);
}

// -----------------------------------------------------------------------------
// ------------------------------ Assemblies -----------------------------------
// -----------------------------------------------------------------------------

// -------------------- Module: lid --------------------
module lid() {
    difference() {
        union () {
            extrude_layer(L_jack_cover, z=fr4_thickness, h=jack_height+wall_thickness, delta=wall_thickness);
            extrude_layer(L_controller_bottom, z=fr4_thickness, h=Z_USB+solder_gap+wall_thickness, delta=wall_thickness);
        }
        extrude_layer(L_jack_cover, z=fr4_thickness, h=jack_height);
        extrude_layer(L_controller_bottom, z=fr4_thickness, h=Z_USB);
        extrude_layer(L_controller_top, z=fr4_thickness+Z_USB, h=solder_gap);
        usb_c_cutout_position();
        jack_cutout();
    }
}

// -------------------- Module: bottom_case --------------------
module bottom_case() {
  difference() {
    extrude_layer(L_plate, z=Z_LID_BASE, h=case_thickness+immersion_depth, delta=wall_thickness);
    extrude_layer(L_plate, z=Z_LID_BASE+case_thickness, h=immersion_depth, delta=clear_pcb_mm);
    extrude_layer(L_solder, z=Z_LID_BASE+case_thickness-solder_gap, h=immersion_depth+solder_gap);
    case_screw_holes();
    jack_cutout();
    usb_c_cutout_position();
    case_feet_holes();
  }
}

// Outline (uses main PCB outline layer) expanded by case wall_thickness
module tent_case_outline() { offset(delta=wall_thickness) import(file=DRAWING, dpi=DPI, layer=L_plate); }

module tent_base_plate() {
  linear_extrude(tent_base_thickness)
    projection()
      rotate([0, -tenting_angle, 0])
        linear_extrude(0.0001)
          offset(delta=tent_clearance + tent_support_wall_thickness)
            tent_case_outline();
}

module tent_support_base() {
  linear_extrude(tent_support_base_thickness)
    difference() {
      offset(delta=tent_clearance + tent_support_wall_thickness)
        tent_case_outline();
      offset(delta=-tent_support_base_width)
        tent_case_outline();
    }
}

module tent_support_walls() {
  translate([0, 0, tent_support_base_thickness])
    linear_extrude(tent_support_wall_height)
      difference() {
        offset(delta=tent_clearance + tent_support_wall_thickness)
          tent_case_outline();
        offset(delta=tent_clearance)
          tent_case_outline();
      }
}

module tent_support() {
  translate([0, 0, tent_base_thickness])
    union() {
      translate([0, 0, tent_support_base_thickness - tent_lowering])
        rotate([0, -tenting_angle, 0])
          union() {
            tent_support_base();
            tent_support_walls();
          }

      difference() {
        linear_extrude()
          projection()
            rotate([0, -tenting_angle, 0])
              linear_extrude(0.0001)
                projection()
                  tent_support_base();

        translate([0, 0, tent_support_base_thickness - tent_lowering])
          rotate([0, -tenting_angle, 0])
            linear_extrude()
              offset(delta=100)
                projection()
                  tent_support_base();
      }
    }
}

// Full tent assembly (base + support structure)
module tent() {
  //tent_base_plate();
  tent_support();
}

// -----------------------------------------------------------------------------
// ------------------------------ Build Select ---------------------------------
// -----------------------------------------------------------------------------
PART = "exploded";

// -------------------- Module: build --------------------
module build() {
  if (PART == "exploded") {
    translate([0, 0, -EXPLODE]) pcb();
    translate([0, 0, -4 * EXPLODE]) bottom_case();
    translate([0, 0, EXPLODE]) lid();
  } else if (PART == "bottom_case")
    bottom_case();
  else if (PART == "tent")
    tent();
  else if (PART == "lid")
    lid();
  else
    echo(str("Unknown PART: ", PART));
}

build();
