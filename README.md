# P2S Optimized G-code

## TL;DR

The P2S is great but its print start & end routines have a couple of flaws.

This updated G-code solves these issues and offers:

- Improved nozzle cleaning
- More quiet initialization
- Remove redundancies
- Improve speed and reliability

## Showcase

### Original / before

![Original nozzle cleaning](assets/original-nozzle-clean.gif)

### Optimized / after

![Optimized nozzle cleaning](assets/optimized-nozzle-clean.gif)


## Disclaimer

	⚠️ USE AT YOUR OWN RISK!

	This custom G-code is provided "as-is" without any warranties of safety or compatibility. This script has been tested to work with PLA and PETG - other materials such as engineering and high-temperature filaments have NOT been tested and therefore may be cause problems.

	By executing this script, you accept full responsibility for any outcomes. The author assumes no liability for hardware damage (such as nozzle crashes or heater failures), financial losses, or personal injuries resulting from the use or modification of this code.

	Before running this script, you must manually verify that the commands match your specific printer model, firmware version, and hardware setup. Always remain by your machine's physical power switch during the initial execution to abort immediately if necessary.

## Why change anything?

I really like the P2S but have felt right from the beginning, that it is not performing on the level that it could hardware-wise. In comparison to the A1 and the A1 mini (especially) it feels less refined and clunky, almost as if it was a bit rushed by Bambu Lab - and then they did not continue to optimize these things after the initial release.

This includes the printer being very noisy during its startup routine and unnecessary movements, homing procedures etc.

Worst of all - and the main reason for me to start optimizing the start code - being the excessive and subpar nozzle wiping that never seems to really get the nozzle clean.

**Exhibit A:** This [YouTube Video](https://www.youtube.com/shorts/HUE2p0dOb1Q) demonstrates the issue quite well (not my video btw).


## What was optimized?

This version of the optimized start code focuses on fixing things that need improvement while the overall structure and process that Bambu Lab intended are kept intact.

The intention being that the procedure is still robust and safe and not targeted towards ultimate speed or certain edge cases that require manual intervention.

Secondly since the original start code is periodically updated, I wanted it to be easy to integrate official changes (like exhaust fan kit, ventobox, filament manager, ...).


**In general:**

- **Added comments:** Most of the G-code was commented to easily understand what is going on. Comments of instructions that appear multiple times in the script have been unified. Added custom comments start with `;;` instead of `;` for distinction. (Some proprietary codes are still unknown and therefore remain unchanged or received `???`.)

- **Formatting:** In some existing commands and comments whitespaces have been added or removed. New lines and section comments have been added for better orientation.


### Start code

**In order (from top to bottom):**

- **Nozzle heating:** Add non-blocking nozzle heating to 140 °C right in the beginning to speed things up.

- **Remove startup sound:** This can also be disabled in the printer menu, but code was still commented out.

- **Decreased Z-Movement:** Default is huge (+22/-12) and has been reduced (+5/-2).

- **Decreased Acceleration:** Acceleration during initialization was 10.000 mm/s² which is quite abrupt and not really necessary during startup and has therefore been reduced to 5.000 mm/s². (Acceleration defined in the slicer is still used at print start.)

- **Enable input shaping:** Motor noise suppression was enabled before turning on input shaping, therefore having no effect and being the reason why startup sequence was louder than it needed to be. (Source: https://www.reddit.com/r/BambuLab/comments/1s8kneu/p2s_quirks_and_poorly_optimized_firmware_settings/)

- **ℹ️ Nozzle Wiping:**
  - **The problem:** During/after filament purge and optional extruder calibration filament poop is ejected and nozzle is wiped multiple times. Yet with the nozzle still being hot filament continues to ooze out - sticking to the nozzle.
  - **The fix:** A little extra filament is being pushed through the nozzle, cooling fan is activated while we wait for the nozzle to reach a lower temperature (currently 170 °C). By doing the purge flick, the cooled down filament is removed from the nozzle without oozing of more filament. Then regular nozzle scraping on the little metal plate is performed.

- **Disabled vibration calibration:** Full vibration compensation can and should be performed from the menu when the printer is moved (and after firmware updates or maintenance). The very short but loud burst of what is called 'mech mode sweep' in the official G-code imho serves no purpose and is therefore removed.

- **Pre-homing:** Before optional bed leveling another homing of all axes is performed. To speed up the process the print head is moved near the XY=0 position where the *endstops* are.

- **Print start:** Before nozzle heating, which by default is done over the poop chute, the build plate is lowered and the print head is moved to the very front of the build plate. This serves two purposes:
  - The nozzle is not moved over the build plate when it is hot, potentially drooping filament onto the build plate.
  - Giving **me** a couple of seconds to remove filament from the nozzle with some tweezers. (Disclaimer: **You should not** have your hands anywhere inside the printer while it's operating. Leaving the door closed is advised.)

- **Load line:** During final heating of the nozzle some filament may start oozing out. To build up pressure the purge line length is increased.

- Actual print start


### End/Stop code

**⚠️ Filament is NOT UNLOADED after printing:**

The default behaviour of any Bambu Lab printer is that after printing the filament is unloaded (when using an AMS).

However often times we want to continue printing using the same filament. Therefore with the custom end G-code this behaviour is changed and the filament **intentionally** is not unloaded - which speeds up consecutive prints (and is less noisy).

If you do use a different filament for your next print, you don't have to do anything and there will be **no problem** since the printer automatically changes the filament at the start of the next print.

If however you do want the filament to be unloaded after a certain print, you may explicitely write `UnloadFilament=1` in the "Notes" field (settings tab "Others" in BambuStudio).


**In order (from top to bottom):**

- **Stop move:** First priority is moving the nozzle away from the print and close to the purge bin before anything else.

- **Keep or unload filament:** See explanation above.

- **Clean nozzle:** If filament is not unloaded, the same nozzle cleaning as in the start code is applied: A little filament is extruded, cooled down and flicked off so the nozzle stays clean for the next print.

- **Remove finish sound:** This can also be disabled in the printer menu, but code was still commented out.


## Repository layout

The folder `optimized` contains all G-codes that have been improved and should be used for a better experience.

The folder `original` contains current versions of the official G-codes by Bambu Lab. These are thought to be updated from time to time to track changes that were made as well as serve as means to compare the optimized G-codes to the default ones.


## Final thoughts

I created this G-code mainly for myself so that I can fully enjoy the printer and get rid of the annoying quirks that otherwise taint the experience for me. I use it every single print.

If you place value on the printer being quiet, I also recommend creating your own default print profile, where you reduce all accelerations from 10000 mm/s² to 6000 mm/s². This adds only very little extra time to your prints but makes the printer much more quiet and stops it shaking violently.

If you have any questions or encounter problems don't hesitate to reach out.
