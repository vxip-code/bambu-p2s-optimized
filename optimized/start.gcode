;M1002 set_flag extrude_cali_flag=1
;M1002 set_flag g29_before_print_flag=1
;M1002 set_flag auto_cali_toolhead_offset_flag=1
;M1002 set_flag build_plate_detect_flag=1

;======== P2S start gcode==========
;===== 2025/11/04 =====
;;==== 2025-12-01 added comments ===


  M140 S[bed_temperature_initial_layer_single] ; heat heatbed first
  
  ;; added
  M104 S140 A ;; set nozzle temp (A = left/first extruder)
  
  M993 A0 B0 C0 ; nozzle cam detection not allowed.
  M400 ;; finish moves


;; ;=====printer start sound ===================
;;   M17 ;; enable steppers
;;   M400 S1 ;; wait 1 second
;;   M1006 S1
;;   M1006 A53 B9 L99 C53 D9 M99 E53 F9 N99
;;   M1006 A56 B9 L99 C56 D9 M99 E56 F9 N99
;;   M1006 A61 B9 L99 C61 D9 M99 E61 F9 N99
;;   M1006 A53 B9 L99 C53 D9 M99 E53 F9 N99
;;   M1006 A56 B9 L99 C56 D9 M99 E56 F9 N99
;;   M1006 A61 B18 L99 C61 D18 M99 E61 F18 N99
;;   M1006 W
;; ;=====printer start sound ===================


  ;; probably ams related commands?
  M620 M ; enable remap
  G389 ;; ???


;; unnecessary huge movement
;; ;===== avoid end stop =================
;;   G91 ;; relative positioning
;;   G380 S2 Z22 F1200 ;; safe z down
;;   G380 S2 Z-12 F1200 ;; safe z up
;;   G90 ;; absolute positioning
;; ;===== avoid end stop =================


; === safe z pos ==
  G91 ;; relativ positioning
  G380 S2 Z5 F1200 ;; safe z down
  G380 S2 Z-2 F1200 ;; safe z up
  G90 ;; absolute positioning
; === safe z pos end ===


;===== reset machine status =================
  M204 S5000 ;; set acceleration to a less noisy 5k (default is 10k)
  M630 S0 P1 ;; ???
  G90 ;; absolute positioning
  M17 D ; reset motor current to default
  M960 S5 P1 ; turn on logo lamp
  G90 ;; absolute positioning
  M220 S100 ; Reset Feedrate
  M1002 set_gcode_claim_speed_level: 5
  M221 S100 ; Reset Flowrate
  M73.2 R1.0 ; Reset left time magnitude
  G29.1 Z{+0.0} ; clear z-trim value first
  M983.1 M1 ;; ???
  M975 S1 ; turn on input shaping ;; added for less noisy startup sequence
  M982.2 S1 ; turn on cog noise reduction
  M983.4 S0 ; ???
;===== reset machine status =================


;==== set airduct mode ==== 
  ;==== if Chamber Cooling is necessary ====
  {if (overall_chamber_temperature >= 40)}
    M145 P1 ; set airduct mode to heating mode for heating
    M106 P2 S255 ; turn on filter fan
  {else}
    {if (min_vitrification_temperature <= 50)}
      M145 P0 ; set airduct mode to cooling mode for cooling
      M106 P2 S255 ; turn on auxiliary fan for cooling
      M1002 gcode_claim_action : 29 ;; status text = ???
      M191 S0 ; wait for chamber temp
      M106 P2 S102 ; turn on chamber cooling fan
      M106 P10 S0 ; turn off left aux fan
    {else}
      M145 P1 ; set airduct mode to heating mode for heating
      M106 P2 S127 ; turn on 50% filter fan
    {endif}
  {endif}
;==== set airduct mode ==== 


;===== start to heat heatbed & hotend==========
  M1002 gcode_claim_action : 2 ;; status text = heatbed preheating
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
  M104 S140 A ;; set nozzle temp (A = left/first extruder)

  G29.2 S0 ; avoid invalid abl data ;; disable bed mesh


;===== first homing start =====
  M1002 gcode_claim_action : 13 ;; status text = homing toolhead
  G28 X T300 ;; home x axis (+ timeout 300?)
  G150.3 ;; move to garbage bin

  M1002 gcode_claim_action : 45 ;; status text = confirm camera
  M972 S24 P0 ;; ??? - camera check? (2 seconds)
  
  M1002 gcode_claim_action : 11 ;; status text = detect build plate
  M972 S26 P0 C0 ;; ??? - build plate detection? (11 seconds, move z down)
  
  M1002 gcode_claim_action : 12 ;; status text = calibrate micro lidar (REPLACE REAL MESSAGE)
  M972 S42 P0 T5000 ;; ??? - nozzle sock detection? (2 seconds)
  
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
  G90 ;; absolute positioning
  G1 X128 Y128 F30000 ;; move xy to center
  G28 Z P0 T400 ;; home z (timout 400?)
  M400 ;; finish moves
;===== first homign end =====


;===== detection start =====
  M1002 gcode_claim_action : 11 ;; status text - identify build plate type
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]-80} A ; rise temp in advance
  M972 S19 P0 T5000 ; plate type detection ;; <== takes 0 seconds?!
;===== detection end =====


;===== prepare print temperature and material ==========
  M400 ;; finish moves
  M211 X0 Y0 Z0 ; turn off soft endstop
  ;; wrong position, moved further up, since input shaping must be called before motor noise reduction
  ;; source: https://www.reddit.com/r/BambuLab/comments/1s8kneu/p2s_quirks_and_poorly_optimized_firmware_settings/
  ;; M975 S1 ; turn on input shaping
  
  G29.2 S0 ; avoid invalid abl data ;; disable bed mesh
  G150.3 ;; move to garbage bin
  
  ;; something special for 0.2 nozzle
  {if ((filament_type[initial_no_support_extruder] == "PLA") || (filament_type[initial_no_support_extruder] == "PLA-CF") || (filament_type[initial_no_support_extruder] == "PETG")) && (nozzle_diameter[initial_no_support_extruder] == 0.2)}
    M620.10 A0 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
    M620.10 A1 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
  {else}
    M620.10 A0 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
    M620.10 A1 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
  {endif}
  
  M620.11 P0 L0 I[initial_no_support_extruder] E0 ;; ??? reset material/extruder state?
  M620.11 K0 I[initial_no_support_extruder] R0 ;; ??? ams related?

  M620 S[initial_no_support_extruder]A ; switch material if AMS exist ;; select ams tray by index
  M1002 gcode_claim_action : 4 ;; status text - changing filament
  M1002 set_filament_type:UNKNOWN
  M400 ;; finish moves
  
  T[initial_no_support_extruder] ;; tool change ==> change filament code??
  
  M400 ;; finish moves
  M628 S0 ;; ??? deactivate ams lock?
  M629 ;; ??? sync ams status?
  M400 ;; finish moves
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]} ;; set material type
  M621 S[initial_no_support_extruder]A ;; ??? confirm ams slot?
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]} ;; set nozzle temp
  M400 ;; finish moves
  M106 P1 S0 ;; fan off
  M400 ;; finish moves
  G29.2 S1 ;; enable bed mesh
;===== prepare print temperature and material ==========


;===== auto extrude cali start =========================
  ;; M975 S1 ;; turn on input shaping ;; disabled since it should already be enabled
  
  M1002 judge_flag extrude_cali_flag ;; set flag for conditional commands (extruder calibration mode)
  
  ;; calibration off
  M622 J0 ;; start conditional block if value=0
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
  M623 ;; end conditional block

  ;; calibration on?
  M622 J1 ;; start conditional block if value=1
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]} ;; set material type
    M1002 gcode_claim_action : 8 ;; status text - calibrating extrusion
    M109 S{nozzle_temperature[initial_no_support_extruder]} ;; wait for nozzle temp
    G90 ;; absolute positioning
    M83 ;; relative extrusion mode
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
    M400 ;; finish moves
    
    ;; disabled
;;    M106 P1 S255 ;; fan on
;;    M400 S10 ;; wait 5 seconds
;;    M106 P1 S0 ;; fan off

    G150.3 ;; move to garbage bin
  M623 ;; end conditional block

  ;; calibration auto?
  M622 J2 ;; start conditional block if value=2
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]} ;; set material type
    M1002 gcode_claim_action : 8 ;; status text - calibrating extrusion
    M109 S{nozzle_temperature[initial_no_support_extruder]} ;; wait for nozzle temp
    G90 ;; absolute positioning
    M83 ;; relative extrusion mode
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
    M400 ;; finish moves
    
    ;; disabled
;;    M106 P1 S255 ;; fan on
;;    M400 S10 ;; wait 5 seconds
;;    M106 P1 S0 ;; fan off

    G150.3 ;; move to garbage bin
  M623 ;; end conditional block
;===== auto extrude cali end =========================


  {if hold_chamber_temp_for_flat_print}
    M1002 gcode_claim_action : 58 ;; status text - ???
    M104 S{first_layer_temperature[initial_no_support_extruder]} ;; nozzle temp
    {if bed_temperature_initial_layer_single > 89}
        M1030 S1800 ;; ???
    {else}
        M1030 S300 ;; ???
    {endif}
    M1030 C ;; ???
  {endif}


;; disabled & rewrite
;;{if filament_type[current_extruder] == "TPU" || filament_type[current_extruder] == "PVA"}
;;{else}
;;  M83 ;; relative extrusion mode
;;  G1 E-3 F1800 ;; retract
;;  M400 P500 ;; ??? pause (P500 unknown)
;;{endif}
;;G150.2 ;; purge flick
;;G150.1 F8000 ;; wipe nozzle
;;G0 Z10 F1200 ;; move z to 10
;;G150.2 ;; purge flick
;;G150.1 F8000 ;; wipe nozzle
;;G0 Z5 F1200 ;; move z to 5
;;G150.1 F8000 ;; wipe nozzle

;;G91 ;; relative positioning
;;G1 Y-16 F12000 ; move away from the trash bin
;;G90 ;; absolute positioning
;;M400 ;; finish moves

;;M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]-80} A ;; set nozzle temp (A = left/first extruder)


  ;; addon
  M1002 gcode_claim_action : 14 ;; status text - cleaning nozzle
  M106 P1 S255 ;; fan on
  M83 ;; relative extrusion mode
  G1 E20 F1800 ;; extrude a bit
  M400 S2 ;; wait a moment
  G1 E30 F1000 ;; extrude a bit more (testing 30, was: 50, 20, 10)
  
  ;;; cut original temp block
  
  {if filament_type[current_extruder] == "TPU" || filament_type[current_extruder] == "PVA"}
    ;; no retract
  {else}
    G1 E-2 F1800 ;; quick rectract
  {endif}
  
  M109 S170 A ;; wait for nozzle to cool down (maybe different temps depending on filament?)
  G150.2 ;; purge flick
  ;;;G150.1 F8000 ;; wipe nozzle
  M106 P1 S0 ;; fan off
  M400 ;; finish moves
  
  ;; set temp and proceed
  {if filament_type[current_extruder] == "PC"}
    M104 S170 A ;; set nozzle temp (+ nozzle A?)
  {else}
    M104 S140 A ;; set nozzle temp (+ nozzle A?)
  {endif}


;; === nozzle cleaning (scraping) ===
  M1002 gcode_claim_action : 14 ;; status text - cleaning nozzle
  {if filament_type[current_extruder] == "PC"}
    G150 T170 ;; nozzle cleaning (scraping on metal pad)
  {else}
    G150 T140 ;; nozzle cleaning (scraping on metal pad)
  {endif}
  M400 ;; finish moves
;; === nozzle cleaning (scraping) ===


  {if filament_type[current_extruder] == "PC"}
    M109 S170 A ;; wait for nozzle temp (+ bambu parameter "A")
  {else}
    M109 S140 A ;; wait for nozzle temp (+ bambu parameter "A")
  {endif}
    G91 ;; relative positioning
    G1 Z5 F1200 ;; lower z by 5
    G90 ;; absolute positioning
    M400 ;; finish moves
    
    G150.3 ;; move to garbage bin
    ;; disabled
    ;;G150.1 ;; wipe nozzle
;===== wipe left nozzle end =====


;===== mech mode sweep start =====
;  M1002 gcode_claim_action : 3 ;; status text - quick vibration compensation
;  G90 ;; absolute positioning
;  G1 X128 Y128 F20000 ;; move xy to center
;  G1 Z5 F1200 ;; move z to 5
;  M400 P200 ;; wait (P200 unknown)
;  M970.3 Q1 A10 K0 O1
;  M970.2 Q1 K1 W74 Z0.01
;  M974 Q1 S2 P0
;  M970.3 Q0 A10 K0 O1
;  M970.2 Q0 K1 W74 Z0.01
;  M974 Q0 S2 P0
;  M975 S1 ;; turn on input shaping
;  M400 ;; finish moves
;===== mech mode sweep end =====


;===== bed leveling ==================================
  M1002 gcode_claim_action : 54 ;; status text - ???
  M190 S[bed_temperature_initial_layer_single] ; ensure bed temp
  M109 S140 A ;; wait for nozzle temp (+ bambu parameter "A")
  M106 S0 ; turn off fan , too noisy
  
  M1002 judge_flag g29_before_print_flag ;; set flag for conditional commands (auto bed mesh)
  
  
  ;; addon - move to pre-homing spot
  G90 ;; absolute positioning
  G1 Y240 F30000 ;; move away from purge bin
  G1 X200 F30000 ;; move near homing area
  M400 ;; finish moves
  
  
  M622 J1 ;; start conditional block if value=1
    M1002 gcode_claim_action : 1 ;; status text - bed leveling
    {if hold_chamber_temp_for_flat_print}
      G29 H ;; ??? complete bed mesh?
    {else}
      G29 A1 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]} ;; ??? print area mesh?
    {endif}
    M400 ;; finish moves
    M500 ; save cali data
  M623

  M622 J2 ;; start conditional block if value=2 (auto?)
    M1002 gcode_claim_action : 1 ;; status text - bed leveling
    {if hold_chamber_temp_for_flat_print}
      G29 H ;; ??? complete bed mesh?
    {else}
      G29 A2 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]} ;; ??? print area mesh?
    {endif}
    M400 ;; finish moves
    M500 ; save cali data
  M623

  M622 J0 ;; start conditional block if value=0 (off)
    G28 ;; home axis
  M623
  G29.2 S1 ;; enable bed mesh
;===== bed leveling end ================================


;; --- first layer temps & cooling ---
  M985.1 U0 E2 ;; ???
  M985.1 U1 E2 ;; ???

  M104 S[nozzle_temperature_initial_layer] A ;; set nozzle temp (A = left/first extruder)
  G150.3 ; move to garbage can to wait for temp

  ;===== wait temperature reaching the reference value =======
  M190 S[bed_temperature_initial_layer_single] ;; wait for bed temperature

  ;========turn off light and fans =============
  M960 S1 P0 ; turn off laser
  M960 S2 P0 ; turn off laser
  M106 S0 ; turn off cooling fan

  ;===== wait temperature reaching the reference value =======
  
  M1002 gcode_claim_action : 255 ;; status text
  M400 ;; finish moves
  ;; M975 S1 ;; turn on input shaping ;; disabled since it should already be enabled
;; --- first layer temps & cooling ---


;============switch again==================
  M211 X0 Y0 Z0 ; turn off soft endstop
  G91 ;; relative positioning
  G1 Z6 F1200 ;; lower z by 6
  G90 ;; absolute positioning
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]} ;; set material type
  M620 S[initial_no_support_extruder]A ;; ??? disable ams filament pullback?
  M400 ;; finish moves
  T[initial_no_support_extruder] ;; tool change
  M400 ;; finish moves
  M628 S0 ;; ??? ams?
  M629 ;; ??? ams?
  M400 ;; finish moves
  M621 S[initial_no_support_extruder]A ;; ??? enable ams filament pullback?
;============switch again==================


;; --- build plate z offset --------------------------
  ;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==
  {if curr_bed_type=="Textured PEI Plate"}
    G29.1 Z{0.01} ; for Textured PEI Plate
  {else}
    G29.1 Z{0.03}
  {endif}
;; --- build plate z offset end ----------------------


;; === bring nozzle to front before heating
G90 ;; absolute positioning
G1 Z50 F1200 ;; lower z to 5cm
G1 X100 Y0 F30000 ;; move front center


;===== nozzle load line ===============================
  M1002 gcode_claim_action : 51 ;; status text
  G29.2 S1 ; ensure z comp turn on ;; enable bed mesh
  G90 ;; absolute positioning
  M83 ;; relative extrusion mode
  M109 S{nozzle_temperature_initial_layer[initial_no_support_extruder]} ;; wait for nozzle temp
  ;G130 O0 X100 Y-0.2 Z0.6 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L40 E12 D4 ;; original v1
  ;G130 O0 X100 Y-0.4 Z0.8 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L40 E20 D5 ;; original v2 - ??? special move command? (length, extrusion, dot size)
  ;G130 O0 X100 Y-0.4 Z0.8 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L60 E30 D6 ;; custom: longer prime line - special move command (length, extrusion, dot size)
  ;; testing longer instead of thicker purge line
  G130 O0 X100 Y-0.4 Z0.6 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L80 E24 D5 ;; custom: longer prime line - special move command (length, extrusion, dot size)
  G90 ;; absolute positioning
  M83 ;; relative extrusion mode
  ;; testing no z-adjustment for quicker nozzle movement
  ;G1 Z0.5 ;; move z to 0.2 (new 0.5 after update)
  M400 ;; finish moves
;===== noozle load line end ===========================


  M1002 gcode_claim_action : 0 ;; status text - clear message?
  G29.99 ;; ???


;; --- dynamic clog detection ------------------------
  {if (filament_type[initial_no_support_extruder] == "TPU")  ||
  (filament_type[initial_no_support_extruder] == "PLA")  ||  (filament_type[initial_no_support_extruder] == "PETG")}
    M1015.3 S1 H[nozzle_diameter] ; enable tpu, pla and petg clog detect
  {else}
    M1015.3 S0 ; disable clog detect
  {endif}
;; --- dynamic clog detection end --------------------


;; --- dynamic air print detection -------------------
  {if (filament_type[initial_no_support_extruder] == "PLA")  ||  (filament_type[initial_no_support_extruder] == "PETG")
  ||  (filament_type[initial_no_support_extruder] == "PLA-CF")  ||  (filament_type[initial_no_support_extruder] == "PETG-CF")}
    M1015.4 S1 K1 H[nozzle_diameter] ; enable E air printing detect
  {else}
    M1015.4 S0 K0 H[nozzle_diameter] ; disable E air printing detect
  {endif}
  
  M620.6 I[initial_no_support_extruder] W1 ; enable ams air printing detect
;; --- dynamic air print detection end ---------------


;; --- ams info --------------------------------------
M1010 Q0 B0.023 S0.01 ;; ???
M1010 Q1 B0.005 S0.01 ;; ???
M1010.1 S1 ;; ???
;; --- ams info end ----------------------------------
