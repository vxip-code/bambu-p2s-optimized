;======== P2S end gcode ==========
;===== 2026/04/01 =====
;; M400 ; wait for buffer to clear
;; G92 E0 ; zero the extruder
;;G1 E-0.8 F1800 ; retract
;;G0 Z{max_layer_z + 0.8} F900

;; raise, retract, park, fan
G91 ;; relative positioning
G1 Z1 F1200 ;; safe z down
G1 E-1 F1800 ;; retract
G90 ;; absolute positioning
G92 E0 ; zero the extruder
G1 X55 Y240 F30000 ;; move near purge bin
M140 S0 ; turn off bed


;;G0 Z{max_layer_z + 0.8} F900
;;G1 E-0.8 F1800 ; retract
;;G150.3 ;; move to garbage bin
;;;M104 S0 ; turn off hotend
;;M106 P1 S255 ;; fan on
;; G1 E20 F1800 ;; extrude
;; G1 E20 F1000 ;; extrude
;; M400 S15 ;; wait
;; G150.1 F8000 ;; wipe nozzle


;; ADDED: keep filament in extruder by default (UNLESS "UnloadFilament=1" is written in the project's process notes)
{if process_notes=~/.*UnloadFilament=1.*/}
    ; pull back filament to AMS
    M620 S65535
    T65535
    ;; G150.2 ;; purge flick
    M621 S65535

{else}
    M1002 gcode_claim_action : 14 ;; status text - cleaning nozzle
    M106 P1 S255 ;; fan on
	M104 S0 ; turn off hotend
	
    G150.3 ;; move to garbage bin
	
	;; move build plate down
    G91 ;; relative positioning
    G1 Z5 F1200 ;; safe z down
    G90 ;; absolute positioning

    ;; clean nozzle
    M83 ;; relative extrusion mode
    G1 E20 F1800 ;; extrude a bit
    M400 S2 ;; wait a moment
    G1 E30 F1000 ;; extrude a bit more (testing 20, was 10)
    
    {if filament_type[current_extruder] == "TPU" || filament_type[current_extruder] == "PVA"}
        ;; no retract
    {else}
        G1 E-2 F1800 ;; quick rectract
    {endif}
{endif}


;; === ADDON for clean nozzle ===
M106 P1 S255 ;; fan on
M109 S170 A ;; wait for nozzle cooldown
M104 S0 ; turn off hotend
;;;M400 S10 ;; wait for cooldown
G150.2 ;; purge flick
;; G150.1 F8000 ;; wipe nozzle
G150.3 ;; move to garbage bin
;;;M400 S10 ;; wait for cooldown
M106 P1 S0 ;; fan off
;; === ADDON for clean nozzle ===

M400 ; wait all motion done

;; === end timelapse ===
M1002 judge_flag timelapse_record_flag
M622 J1
    M991 S0 P-1 ; end smooth timelapse at safe pos
    M400 S5 ; wait for last picture to be taken
M623  ; end of "timelapse_record_flag"
;; === end timelapse ====


;; === stop fans & heating ===
M104 S0 ; turn off hotend
M140 S0 ; turn off bed
;;M106 S0 ; turn off fan
M106 P2 S0 ; turn off remote part cooling fan
M106 P3 S0 ; turn off chamber cooling fan
M106 P10 S0 ; turn off left aux fan
;; === stop fans & heating ===


;; === lower bed safely ===
M400 ; wait all motion done
M17 S
M17 Z0.4 ; lower z motor current to reduce impact if there is something in the bottom
{if (80.0 - max_layer_z/2) > 0}
    {if (max_layer_z + 80.0 - max_layer_z/2) < 256}
        G1 Z{max_layer_z + 80.0 - max_layer_z/2} F600
        G1 Z{max_layer_z + 78.0 - max_layer_z/2}
    {else}
        G1 Z256 F600
        G1 Z256
    {endif}
{else}
    {if (max_layer_z + 4.0) < 256}
        G1 Z{max_layer_z + 4.0} F600
        G1 Z{max_layer_z + 2.0}
    {else}
        G1 Z256 F600
        G1 Z256
    {endif}
{endif}
M400 P100
M17 R ; restore z current
;; === lower bed safely ===


;; === reset values ===
M220 S100  ; Reset feedrate magnitude
M201.2 K1.0 ; Reset acc magnitude
M73.2 R1.0 ; Reset left time magnitude
M1002 set_gcode_claim_speed_level : 0 ; Reset speed mode

M1015.3 S0 ; disable clog detect
M1015.4 S0 K0 ; disable air printing detect
;; === reset values ===


;=====printer finish air purification=========
M622.1 S0
M1002 judge_flag print_finish_air_filt_flag

M622 J1
M1002 gcode_claim_action : 66
M145 P1
M106 P2 S255
M400 S180
M106 P2 S0
M623

M622 J2
M1002 gcode_claim_action : 66
M145 P0
M106 P3 S255
M400 S180
M106 P3 S0
M623
;=====printer finish air purification=========


;=====printer finish sound=========
;;M17
;;M400 S1
;;M1006 S1
;;M1006 A53 B10 L99 C53 D10 M99 E53 F10 N99 
;;M1006 A57 B10 L99 C57 D10 M99 E57 F10 N99 
;;M1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 
;;M1006 A53 B10 L99 C53 D10 M99 E53 F10 N99 
;;M1006 A57 B10 L99 C57 D10 M99 E57 F10 N99 
;;M1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 
;;M1006 A48 B10 L99 C48 D10 M99 E48 F10 N99 
;;M1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 
;;M1006 A60 B10 L99 C60 D10 M99 E60 F10 N99 
;;M1006 W
;=====printer finish sound=========


;; === final shutdown ===
M400 ;; finish moves
M18 ;; disabled motors
;; === final shutdown ===