# On-screen text

Generated: 2026-11-09

**Entries:** 555
**Painted:** 56
**Template:** 80

Quoted words are the current player-facing text. `{braces}` name an inserted piece. They are not drawn as braces. The same words on two screens are listed twice. Painted letters live in an image. Code letters are drawn by script.

Counts above cover the entries through Unlock and save notes. The last section, Not drawn, is excluded from the counts.

Screens in the order a player meets them: window title with the title screen, main menu, Options, character select, in-kick HUD, in-kick vitamin belt, kick meter, kick result, loadout offer, loadout rail tooltip, Vitamin Shop, Trophy Room, end of run, then mulligan, curse removal, trophy popup, and unlock or save notes.

No pause screen exists. Esc during a kick is not given its own pause menu. A price the player cannot afford in the Vitamin Shop turns red and adds no words. Flight has no bottom hint. Shelf bottles in the shop painting do not carry readable words. Item and vitamin sprites do not carry readable words, except the Drive Lid icon, which has no sprite and draws Drive.

## Title

### `window_title`
- **screen:** Title
- **when:** Operating-system window title while the game is open.
- **current:** "Field Goal"
- **kind:** static
- **source:** code

### `title_wordmark`
- **screen:** Title
- **when:** Painted on art/ui/title.png, center of the title screen.
- **current:** "OVERTIME 2000"
- **kind:** static
- **source:** painted

### `title_press_start`
- **screen:** Title
- **when:** Painted under the wordmark. The letters pulse brighter and dimmer. No second copy is drawn while the art loads.
- **current:** "PRESS START"
- **kind:** static
- **source:** painted

### `title_fallback_wordmark`
- **screen:** Title
- **when:** Failsafe, only if the title art fails to load.
- **current:** "OVERTIME 2000"
- **kind:** static
- **source:** code

### `title_fallback_press_start`
- **screen:** Title
- **when:** Failsafe, only if the title art fails to load. Drawn in the PRESS START hit area.
- **current:** "PRESS START"
- **kind:** static
- **source:** code

## Main menu

### `menu_wordmark`
- **screen:** Main menu
- **when:** Painted on art/ui/main_menu.png above the four tiles.
- **current:** "OVERTIME 2000"
- **kind:** static
- **source:** painted

### `menu_standard`
- **screen:** Main menu
- **when:** Painted on the first tile. A white rounded outline and whitened letters mark the selection. No filled box is drawn over the tile.
- **current:** "STANDARD"
- **kind:** static
- **source:** painted

### `menu_endless`
- **screen:** Main menu
- **when:** Painted on the second tile, locked or unlocked.
- **current:** "ENDLESS"
- **kind:** static
- **source:** painted

### `menu_trophy_room`
- **screen:** Main menu
- **when:** Painted on the third tile, on two lines.
- **current:** "TROPHY ROOM"
- **kind:** static
- **source:** painted

### `menu_options`
- **screen:** Main menu
- **when:** Painted on the fourth tile.
- **current:** "OPTIONS"
- **kind:** static
- **source:** painted

### `menu_endless_lock`
- **screen:** Main menu
- **when:** Banner after choosing Endless before Standard has been won.
- **current:** "Beat Standard mode to unlock"
- **kind:** static
- **source:** code

### `menu_endless_infinity`
- **screen:** Main menu
- **when:** After Endless is unlocked. There is no endless_unlocked.png, so a gray patch and this glyph are drawn over the painted lock. The painted word ENDLESS stays.
- **current:** "∞"
- **kind:** static
- **source:** code

### `menu_fallback_wordmark`
- **screen:** Main menu
- **when:** Failsafe, only if the main-menu art fails to load. The four tile words are painted, so they are not replaced by code.
- **current:** "OVERTIME 2000"
- **kind:** static
- **source:** code

## Options

### `options_header`
- **screen:** Options
- **when:** Painted header on art/ui/options.png.
- **current:** "OPTIONS"
- **kind:** static
- **source:** painted

### `options_audio`
- **screen:** Options
- **when:** Painted section title on the left panel.
- **current:** "AUDIO"
- **kind:** static
- **source:** painted

### `options_music`
- **screen:** Options
- **when:** Painted label for the first volume slider.
- **current:** "MUSIC"
- **kind:** static
- **source:** painted

### `options_crowd`
- **screen:** Options
- **when:** Painted label for the second volume slider.
- **current:** "CROWD"
- **kind:** static
- **source:** painted

### `options_special_effects`
- **screen:** Options
- **when:** Painted label for the third volume slider. The code id is sfx. No on-screen word says SFX.
- **current:** "SPECIAL EFFECTS"
- **kind:** static
- **source:** painted

### `options_controls`
- **screen:** Options
- **when:** Painted section title on the right panel.
- **current:** "CONTROLS"
- **kind:** static
- **source:** painted

### `options_confirm_kick`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "CONFIRM / KICK"
- **kind:** static
- **source:** painted

### `options_aim_left`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "AIM LEFT"
- **kind:** static
- **source:** painted

### `options_aim_right`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "AIM RIGHT"
- **kind:** static
- **source:** painted

### `options_menu_up`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "MENU UP"
- **kind:** static
- **source:** painted

### `options_menu_down`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "MENU DOWN"
- **kind:** static
- **source:** painted

### `options_back_cancel`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "BACK / CANCEL"
- **kind:** static
- **source:** painted

### `options_choose_1`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "CHOOSE 1"
- **kind:** static
- **source:** painted

### `options_choose_2`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "CHOOSE 2"
- **kind:** static
- **source:** painted

### `options_choose_3`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "CHOOSE 3"
- **kind:** static
- **source:** painted

### `options_buy_b12`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "BUY B12"
- **kind:** static
- **source:** painted

### `options_skip`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "SKIP"
- **kind:** static
- **source:** painted

### `options_belt_z`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "BELT Z"
- **kind:** static
- **source:** painted

### `options_belt_x`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "BELT X"
- **kind:** static
- **source:** painted

### `options_shop_reroll`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "SHOP REROLL"
- **kind:** static
- **source:** painted

### `options_offer_reroll`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "OFFER REROLL"
- **kind:** static
- **source:** painted

### `options_practice_swing`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "PRACTICE SWING"
- **kind:** static
- **source:** painted

### `options_trophy_room`
- **screen:** Options
- **when:** Painted action name on art/ui/options.png. The key chip to its right is covered and redrawn in code.
- **current:** "TROPHY ROOM"
- **kind:** static
- **source:** painted

### `options_reset_controls`
- **screen:** Options
- **when:** Painted button. Choosing it restores the default keys. No extra confirmation words are drawn.
- **current:** "RESET CONTROLS"
- **kind:** static
- **source:** painted

### `options_back`
- **screen:** Options
- **when:** Painted button. Returns to the main menu.
- **current:** "BACK (ESC)"
- **kind:** static
- **source:** painted

### `options_painted_space`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "SPACE"
- **kind:** static
- **source:** painted

### `options_painted_left`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "LEFT"
- **kind:** static
- **source:** painted

### `options_painted_right`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "RIGHT"
- **kind:** static
- **source:** painted

### `options_painted_up`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "UP"
- **kind:** static
- **source:** painted

### `options_painted_down`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "DOWN"
- **kind:** static
- **source:** painted

### `options_painted_esc`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "ESC"
- **kind:** static
- **source:** painted

### `options_painted_1`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "1"
- **kind:** static
- **source:** painted

### `options_painted_2`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "2"
- **kind:** static
- **source:** painted

### `options_painted_3`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "3"
- **kind:** static
- **source:** painted

### `options_painted_4`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "4"
- **kind:** static
- **source:** painted

### `options_painted_s`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "S"
- **kind:** static
- **source:** painted

### `options_painted_z`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "Z"
- **kind:** static
- **source:** painted

### `options_painted_x`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "X"
- **kind:** static
- **source:** painted

### `options_painted_f`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "F"
- **kind:** static
- **source:** painted

### `options_painted_r`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "R"
- **kind:** static
- **source:** painted

### `options_painted_p`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "P"
- **kind:** static
- **source:** painted

### `options_painted_t`
- **screen:** Options
- **when:** Painted default key on art/ui/options.png. A code plate covers it and draws the live key name, which matches this word until the bind changes.
- **current:** "T"
- **kind:** static
- **source:** painted

### `options_fallback_header`
- **screen:** Options
- **when:** Failsafe, only if the Options art fails to load.
- **current:** "OPTIONS"
- **kind:** static
- **source:** code

### `options_key_chip`
- **screen:** Options
- **when:** Live key on each control row. Named keys the code spells itself are SPACE, ESC, LEFT, RIGHT, UP, DOWN, ENTER, TAB. An unknown code is ?. Any other key is the engine key name in uppercase, such as A, 1, or F.
- **current:** "{key_name}"
- **kind:** template
- **source:** code

### `options_rebind_prompt`
- **screen:** Options
- **when:** On the key chip while that row is waiting for a new key.
- **current:** "Press a key..."
- **kind:** static
- **source:** code

### `options_already_used`
- **screen:** Options
- **when:** Banner when the new key is already used, or when it is C, W, or F9.
- **current:** "Already used"
- **kind:** static
- **source:** code

## Character select

### `select_title`
- **screen:** Character select
- **when:** Top of the eight-card select screen.
- **current:** "Choose your kicker"
- **kind:** static
- **source:** code

### `select_locked`
- **screen:** Character select
- **when:** On a locked kicker card, under the name, in place of the kit.
- **current:** "LOCKED"
- **kind:** static
- **source:** code

### `select_footer`
- **screen:** Character select
- **when:** Bottom of character select. The digits and Space are written out. They do not follow Options rebinds.
- **current:** "1–8 highlight.  Space or click again to start."
- **kind:** static
- **source:** code

### `select_bruce_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Big Bruce"
- **kind:** static
- **source:** code

### `select_bruce_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "65 yd"
- **kind:** static
- **source:** code

### `select_bruce_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Farm Strength. A press under 80% still kicks at 80%."
- **kind:** static
- **source:** code

### `select_bruce_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "The Farm Ball"
- **kind:** static
- **source:** code

### `select_bruce_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "A light hay ball. Wind moves it 10% more than a normal ball. A doink stays a doink."
- **kind:** static
- **source:** code

### `select_walk_on_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "The Walk-On"
- **kind:** static
- **source:** code

### `select_walk_on_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "60 yd"
- **kind:** static
- **source:** code

### `select_walk_on_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Earns His Spot. 2 rerolls a run."
- **kind:** static
- **source:** code

### `select_walk_on_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "Team-Issue"
- **kind:** static
- **source:** code

### `select_walk_on_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "A normal ball. No special trick."
- **kind:** static
- **source:** code

### `select_phil_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Phil The Pharmacist"
- **kind:** static
- **source:** code

### `select_phil_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "55 yd"
- **kind:** static
- **source:** code

### `select_phil_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "House Account. Compounding. Shop items are free and 15% stronger."
- **kind:** static
- **source:** code

### `select_phil_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "The Gelcap"
- **kind:** static
- **source:** code

### `select_phil_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "A vitamin used on this attempt adds +0.5 Mult on a make."
- **kind:** static
- **source:** code

### `select_phil_unlock`
- **screen:** Character select
- **when:** Under LOCKED, while this kicker is locked. Also shown in the save-note banner if the locked card is confirmed.
- **current:** "Buy something from the Vitamin Shop"
- **kind:** static
- **source:** code

### `select_gary_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Gary the Goat"
- **kind:** static
- **source:** code

### `select_gary_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "65 yd"
- **kind:** static
- **source:** code

### `select_gary_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Good As Gold. The good band counts as PERFECT."
- **kind:** static
- **source:** code

### `select_gary_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "Lucky Ball"
- **kind:** static
- **source:** code

### `select_gary_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "Each first-try make boosts item numbers by 3% for the rest of the run."
- **kind:** static
- **source:** code

### `select_gary_unlock`
- **screen:** Character select
- **when:** Under LOCKED, while this kicker is locked. Also shown in the save-note banner if the locked card is confirmed.
- **current:** "Beat Standard without a miss"
- **kind:** static
- **source:** code

### `select_vex_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Vex"
- **kind:** static
- **source:** code

### `select_vex_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "Infinite Range & Beyond"
- **kind:** static
- **source:** code

### `select_vex_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Infinite Range & Beyond. 88% power clears by 5 yards."
- **kind:** static
- **source:** code

### `select_vex_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "The Flying Saucer"
- **kind:** static
- **source:** code

### `select_vex_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "Curves left like 8 mph of west wind, on top of the real wind."
- **kind:** static
- **source:** code

### `select_vex_unlock`
- **screen:** Character select
- **when:** Under LOCKED, while this kicker is locked. Also shown in the save-note banner if the locked card is confirmed.
- **current:** "Fail an Endless run past 75 yards"
- **kind:** static
- **source:** code

### `select_cole_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Cole Lang"
- **kind:** static
- **source:** code

### `select_cole_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "70 yd"
- **kind:** static
- **source:** code

### `select_cole_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Brand Deal. Loadout offers stay. The Vitamin Shop does not."
- **kind:** static
- **source:** code

### `select_cole_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "Showtime"
- **kind:** static
- **source:** code

### `select_cole_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "A down-the-middle make doubles stored Mult, and that kick scores with the doubled Mult."
- **kind:** static
- **source:** code

### `select_cole_unlock`
- **screen:** Character select
- **when:** Under LOCKED, while this kicker is locked. Also shown in the save-note banner if the locked card is confirmed.
- **current:** "Beat Standard"
- **kind:** static
- **source:** code

### `select_willow_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Willow Reed"
- **kind:** static
- **source:** code

### `select_willow_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "50 yd"
- **kind:** static
- **source:** code

### `select_willow_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Synchronicity. The first shop opening includes a range vitamin."
- **kind:** static
- **source:** code

### `select_willow_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "The Chill Ball"
- **kind:** static
- **source:** code

### `select_willow_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "Both needles run at half speed. Items and weather still stack on top."
- **kind:** static
- **source:** code

### `select_willow_unlock`
- **screen:** Character select
- **when:** Under LOCKED, while this kicker is locked. Also shown in the save-note banner if the locked card is confirmed.
- **current:** "Make a kick with 1 attempt left (kick 5+)"
- **kind:** static
- **source:** code

### `select_carlos_name`
- **screen:** Character select
- **when:** Kicker card name. Shown locked or unlocked.
- **current:** "Carlos Hernandez"
- **kind:** static
- **source:** code

### `select_carlos_range`
- **screen:** Character select
- **when:** Under the name, only while this kicker is unlocked.
- **current:** "66 yd"
- **kind:** static
- **source:** code

### `select_carlos_excels`
- **screen:** Character select
- **when:** Kit line under the range, only while this kicker is unlocked.
- **current:** "Numero Dos. A 95–100 lock is a true PERFECT."
- **kind:** static
- **source:** code

### `select_carlos_ball`
- **screen:** Character select
- **when:** Ball name under the kit, only while this kicker is unlocked.
- **current:** "The Not So Secret Weapon"
- **kind:** static
- **source:** code

### `select_carlos_ball_text`
- **screen:** Character select
- **when:** Ball description under the ball name, only while this kicker is unlocked.
- **current:** "Both needles run 15% faster. Items and weather still stack on top."
- **kind:** static
- **source:** code

### `select_carlos_unlock`
- **screen:** Character select
- **when:** Under LOCKED, while this kicker is locked. Also shown in the save-note banner if the locked card is confirmed.
- **current:** "Make a 100-yard field goal"
- **kind:** static
- **source:** code

## In-kick HUD

### `hud_kick_of`
- **screen:** In-kick HUD
- **when:** Standard mode, top of the left panel. {kick_number} is the current kick. {season_length} is 20.
- **current:** "Kick {kick_number} of {season_length}"
- **kind:** template
- **source:** code

### `hud_kick_endless`
- **screen:** In-kick HUD
- **when:** Endless mode, top of the left panel.
- **current:** "Kick {kick_number}"
- **kind:** template
- **source:** code

### `hud_distance`
- **screen:** In-kick HUD
- **when:** Under the kick line.
- **current:** "{yards} yd"
- **kind:** template
- **source:** code

### `hud_spot_left_wide`
- **screen:** In-kick HUD
- **when:** Spot line under the distance.
- **current:** "LEFT WIDE"
- **kind:** static
- **source:** code

### `hud_spot_left_hash`
- **screen:** In-kick HUD
- **when:** Spot line under the distance.
- **current:** "LEFT HASH"
- **kind:** static
- **source:** code

### `hud_spot_center`
- **screen:** In-kick HUD
- **when:** Spot line under the distance.
- **current:** "CENTER"
- **kind:** static
- **source:** code

### `hud_spot_right_hash`
- **screen:** In-kick HUD
- **when:** Spot line under the distance.
- **current:** "RIGHT HASH"
- **kind:** static
- **source:** code

### `hud_spot_right_wide`
- **screen:** In-kick HUD
- **when:** Spot line under the distance.
- **current:** "RIGHT WIDE"
- **kind:** static
- **source:** code

### `hud_score_streak`
- **screen:** In-kick HUD
- **when:** Under the spot.
- **current:** "Score {score}    Streak {streak}"
- **kind:** template
- **source:** code

### `hud_mult`
- **screen:** In-kick HUD
- **when:** Under the score. {mult} is two decimal places.
- **current:** "Mult {mult}"
- **kind:** template
- **source:** code

### `hud_attempts_label`
- **screen:** In-kick HUD
- **when:** Label beside the attempt pips. The pips themselves have no words.
- **current:** "ATTEMPTS"
- **kind:** static
- **source:** code

### `hud_attempts_count`
- **screen:** In-kick HUD
- **when:** After the attempt pips.
- **current:** "{attempts} / cap {cap}"
- **kind:** template
- **source:** code

### `hud_bruce_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Big Bruce"
- **kind:** static
- **source:** code

### `hud_bruce_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Farm Strength"
- **kind:** static
- **source:** code

### `hud_bruce_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "The Farm Ball"
- **kind:** static
- **source:** code

### `hud_walk_on_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "The Walk-On"
- **kind:** static
- **source:** code

### `hud_walk_on_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Earns His Spot"
- **kind:** static
- **source:** code

### `hud_walk_on_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "Team-Issue"
- **kind:** static
- **source:** code

### `hud_phil_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Phil The Pharmacist"
- **kind:** static
- **source:** code

### `hud_phil_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "House Account"
- **kind:** static
- **source:** code

### `hud_phil_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "The Gelcap"
- **kind:** static
- **source:** code

### `hud_gary_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Gary the Goat"
- **kind:** static
- **source:** code

### `hud_gary_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Good As Gold"
- **kind:** static
- **source:** code

### `hud_gary_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "Lucky Ball"
- **kind:** static
- **source:** code

### `hud_vex_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Vex"
- **kind:** static
- **source:** code

### `hud_vex_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Infinite Range & Beyond"
- **kind:** static
- **source:** code

### `hud_vex_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "The Flying Saucer"
- **kind:** static
- **source:** code

### `hud_cole_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Cole Lang"
- **kind:** static
- **source:** code

### `hud_cole_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Brand Deal"
- **kind:** static
- **source:** code

### `hud_cole_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "Showtime"
- **kind:** static
- **source:** code

### `hud_willow_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Willow Reed"
- **kind:** static
- **source:** code

### `hud_willow_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Synchronicity"
- **kind:** static
- **source:** code

### `hud_willow_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "The Chill Ball"
- **kind:** static
- **source:** code

### `hud_carlos_name`
- **screen:** In-kick HUD
- **when:** This kicker's name on the left panel.
- **current:** "Carlos Hernandez"
- **kind:** static
- **source:** code

### `hud_carlos_kit`
- **screen:** In-kick HUD
- **when:** Short kit name under the kicker name. It is the opening of that kicker's character-select excels line.
- **current:** "Numero Dos"
- **kind:** static
- **source:** code

### `hud_carlos_ball`
- **screen:** In-kick HUD
- **when:** This kicker's ball name on the left panel.
- **current:** "The Not So Secret Weapon"
- **kind:** static
- **source:** code

### `hud_aim`
- **screen:** In-kick HUD
- **when:** Bottom of the left panel. {degrees} is a signed tenth, such as +1.2 or 0.0. Negative means left.
- **current:** "Aim {degrees}°   negative is left"
- **kind:** template
- **source:** code

### `hud_boss_kick`
- **screen:** In-kick HUD
- **when:** Centered during a boss kick, while the run is still being played.
- **current:** "BOSS KICK"
- **kind:** static
- **source:** code

### `hud_weather_clear`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "CLEAR"
- **kind:** static
- **source:** code

### `hud_weather_rain`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "RAIN"
- **kind:** static
- **source:** code

### `hud_weather_snow`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "SNOW"
- **kind:** static
- **source:** code

### `hud_weather_mud`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "MUD"
- **kind:** static
- **source:** code

### `hud_weather_thin_air`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "THIN AIR"
- **kind:** static
- **source:** code

### `hud_weather_iced`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "ICED"
- **kind:** static
- **source:** code

### `hud_weather_squeeze`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "THE SQUEEZE"
- **kind:** static
- **source:** code

### `hud_weather_monsoon`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "MONSOON"
- **kind:** static
- **source:** code

### `hud_weather_big_game`
- **screen:** In-kick HUD
- **when:** Weather or boss name centered under BOSS KICK.
- **current:** "BIG GAME"
- **kind:** static
- **source:** code

### `hud_meter_upgrades_off`
- **screen:** In-kick HUD
- **when:** Under the weather name during Big Game.
- **current:** "Meter upgrades off"
- **kind:** static
- **source:** code

### `hud_howling_banner`
- **screen:** In-kick HUD
- **when:** Centered curse line while Howling Wind is active. Replaces the plain curse-name list.
- **current:** "Howling Wind   wind ×1.5   items ×1.15"
- **kind:** static
- **source:** code

### `hud_curse_names`
- **screen:** In-kick HUD
- **when:** Centered curse line when at least one curse is held and Howling Wind is not. Names are separated by a comma and a space.
- **current:** "{curse_name}, {curse_name}"
- **kind:** template
- **source:** code

### `hud_curse_iced`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Iced"
- **kind:** static
- **source:** code

### `hud_curse_shanky_cleats`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Shanky Cleats"
- **kind:** static
- **source:** code

### `hud_curse_heavy_ball`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Heavy Ball"
- **kind:** static
- **source:** code

### `hud_curse_howling_wind`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Howling Wind"
- **kind:** static
- **source:** code

### `hud_curse_shaky_arrow`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Shaky Arrow"
- **kind:** static
- **source:** code

### `hud_curse_narrow_posts`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Narrow Posts"
- **kind:** static
- **source:** code

### `hud_curse_stone_toe`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Stone Toe"
- **kind:** static
- **source:** code

### `hud_curse_tight_window`
- **screen:** In-kick HUD
- **when:** Curse name that can appear in that centered line.
- **current:** "Tight Window"
- **kind:** static
- **source:** code

### `hud_wind_calm`
- **screen:** In-kick HUD
- **when:** Wind name by the flag on the field. Calm is 0 mph, Breezy is 1–7, Windy is 8–15, GALE is 16 or more.
- **current:** "Calm"
- **kind:** static
- **source:** code

### `hud_wind_breezy`
- **screen:** In-kick HUD
- **when:** Wind name by the flag on the field. Calm is 0 mph, Breezy is 1–7, Windy is 8–15, GALE is 16 or more.
- **current:** "Breezy"
- **kind:** static
- **source:** code

### `hud_wind_windy`
- **screen:** In-kick HUD
- **when:** Wind name by the flag on the field. Calm is 0 mph, Breezy is 1–7, Windy is 8–15, GALE is 16 or more.
- **current:** "Windy"
- **kind:** static
- **source:** code

### `hud_wind_gale`
- **screen:** In-kick HUD
- **when:** Wind name by the flag on the field. Calm is 0 mph, Breezy is 1–7, Windy is 8–15, GALE is 16 or more.
- **current:** "GALE"
- **kind:** static
- **source:** code

### `hud_wind_readout`
- **screen:** In-kick HUD
- **when:** Under the wind name, only while Wind Visor rank I or higher (or Lutein) has turned the flag reader on. {cross} and {tail} are signed numbers.
- **current:** "{mph} mph   cross {cross}   tail {tail}"
- **kind:** template
- **source:** code

### `hud_hint_aim`
- **screen:** In-kick HUD
- **when:** Bottom hint while aiming, when a practice swing is not offered and this kick is not already a practice swing. {aim_left}, {aim_right}, and {confirm} are the live key names. Defaults are LEFT, RIGHT, and SPACE.
- **current:** "Hold {aim_left} or {aim_right} to aim.   {confirm} starts the meter."
- **kind:** template
- **source:** code

### `hud_hint_aim_practice`
- **screen:** In-kick HUD
- **when:** Bottom hint while aiming when a practice swing can still be used. The P is written out. It does not follow the PRACTICE SWING rebind.
- **current:** "Hold {aim_left} or {aim_right} to aim.   {confirm} starts the meter.   P: practice."
- **kind:** template
- **source:** code

### `hud_hint_aim_practicing`
- **screen:** In-kick HUD
- **when:** Bottom hint while aiming during a practice swing.
- **current:** "Hold {aim_left} or {aim_right} to aim.   {confirm} starts the meter.   Practice swing."
- **kind:** template
- **source:** code

### `hud_hint_power`
- **screen:** In-kick HUD
- **when:** Bottom hint while the power needle is moving. {confirm} defaults to SPACE.
- **current:** "{confirm} locks power."
- **kind:** template
- **source:** code

### `hud_hint_accuracy`
- **screen:** In-kick HUD
- **when:** Bottom hint while the accuracy needle is moving.
- **current:** "{confirm} locks accuracy."
- **kind:** template
- **source:** code

### `hud_hint_result`
- **screen:** In-kick HUD
- **when:** Bottom hint on the result banner, until the player continues. Hidden during mulligan, the loadout offer, and the curse prompt.
- **current:** "{confirm}: continue."
- **kind:** template
- **source:** code

## In-kick vitamin belt

### `belt_cash`
- **screen:** In-kick vitamin belt
- **when:** Cash on the belt plate, under the left panel.
- **current:** "${cash}"
- **kind:** template
- **source:** code

### `belt_cash_popup`
- **screen:** In-kick vitamin belt
- **when:** Beside the cash after a make that pays. Hidden when the payout is 0.
- **current:** "+${amount}"
- **kind:** template
- **source:** code

### `belt_key_z`
- **screen:** In-kick vitamin belt
- **when:** On the first belt slot. Written as Z, not the live BELT Z bind.
- **current:** "Z"
- **kind:** static
- **source:** code

### `belt_key_x`
- **screen:** In-kick vitamin belt
- **when:** On the second belt slot. Written as X, not the live BELT X bind.
- **current:** "X"
- **kind:** static
- **source:** code

### `belt_vitamin_name`
- **screen:** In-kick vitamin belt
- **when:** Pattern for a filled belt slot. The exact names that can appear are listed next. An empty slot has no words.
- **current:** "{vitamin_name}"
- **kind:** template
- **source:** code

### `belt_name_protein_shake`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Protein Shake"
- **kind:** static
- **source:** code

### `belt_name_magnesium`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Magnesium"
- **kind:** static
- **source:** code

### `belt_name_omega_3`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Omega-3"
- **kind:** static
- **source:** code

### `belt_name_electrolyte_tabs`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Electrolyte Tabs"
- **kind:** static
- **source:** code

### `belt_name_vitamin_d`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Vitamin D"
- **kind:** static
- **source:** code

### `belt_name_pre_workout`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Pre-Workout"
- **kind:** static
- **source:** code

### `belt_name_zinc`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Zinc"
- **kind:** static
- **source:** code

### `belt_name_lutein`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Lutein"
- **kind:** static
- **source:** code

### `belt_name_pickle_juice`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Pickle Juice"
- **kind:** static
- **source:** code

### `belt_name_tart_cherry`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "Tart Cherry"
- **kind:** static
- **source:** code

### `belt_name_b12_shot`
- **screen:** In-kick vitamin belt
- **when:** Name on a filled in-kick belt slot.
- **current:** "B12 Shot"
- **kind:** static
- **source:** code

### `belt_note_already_rerolled`
- **screen:** In-kick vitamin belt
- **when:** Belt note if Zinc is used again after it already rerolled this kick.
- **current:** "Already rerolled"
- **kind:** static
- **source:** code

### `belt_note_used_name`
- **screen:** In-kick vitamin belt
- **when:** Belt note after using a vitamin that is not opening the curse picker. The words are that vitamin's name.
- **current:** "{vitamin_name}"
- **kind:** template
- **source:** code

### `belt_note_no_curse`
- **screen:** In-kick vitamin belt
- **when:** Belt note if Tart Cherry is used with no curse held.
- **current:** "No curse to remove"
- **kind:** static
- **source:** code

### `belt_note_curse_removed`
- **screen:** In-kick vitamin belt
- **when:** Belt note after a curse is removed.
- **current:** "Curse removed"
- **kind:** static
- **source:** code

### `belt_note_remove_which`
- **screen:** In-kick vitamin belt
- **when:** Belt note while the curse-removal overlay is open.
- **current:** "Remove which curse?"
- **kind:** static
- **source:** code

## Kick meter

### `meter_power`
- **screen:** Kick meter
- **when:** Painted on the lower-left bezel of art/ui/kick_meter.png. Stays visible.
- **current:** "POWER"
- **kind:** static
- **source:** painted

### `meter_max`
- **screen:** Kick meter
- **when:** Painted at the top of the bezel. Stays visible.
- **current:** "MAX"
- **kind:** static
- **source:** painted

### `meter_accuracy`
- **screen:** Kick meter
- **when:** Painted on the lower-right bezel. Stays visible.
- **current:** "ACCURACY"
- **kind:** static
- **source:** painted

### `meter_painted_good_high`
- **screen:** Kick meter
- **when:** Painted on the upper yellow wedge of kick_meter.png. The live wedge is drawn on top of it.
- **current:** "GOOD"
- **kind:** static
- **source:** painted

### `meter_painted_perfect`
- **screen:** Kick meter
- **when:** Painted on the green wedge of kick_meter.png. The live wedge is drawn on top of it.
- **current:** "PERFECT"
- **kind:** static
- **source:** painted

### `meter_painted_good_low`
- **screen:** Kick meter
- **when:** Painted on the lower yellow wedge of kick_meter.png. The live wedge is drawn on top of it.
- **current:** "GOOD"
- **kind:** static
- **source:** painted

### `meter_good_high`
- **screen:** Kick meter
- **when:** Code label on the upper good wedge. This is the readable GOOD above PERFECT.
- **current:** "GOOD"
- **kind:** static
- **source:** code

### `meter_perfect`
- **screen:** Kick meter
- **when:** Code label in the middle of the perfect wedge.
- **current:** "PERFECT"
- **kind:** static
- **source:** code

### `meter_good_low`
- **screen:** Kick meter
- **when:** Code label on the lower good wedge.
- **current:** "GOOD"
- **kind:** static
- **source:** code

## Kick result

### `result_bank_shot`
- **screen:** Kick result
- **when:** Result banner when a doink is turned into a make by bank-shot rules. No current judge path sets this, but the banner still draws it if the flag is on.
- **current:** "BANK SHOT!"
- **kind:** static
- **source:** code

### `result_insured`
- **screen:** Kick result
- **when:** Result banner when Doink Cap turns a doink into a make.
- **current:** "INSURED!"
- **kind:** static
- **source:** code

### `result_perfect`
- **screen:** Kick result
- **when:** Result banner when the kick was perfect.
- **current:** "PERFECT!"
- **kind:** static
- **source:** code

### `result_down_the_middle`
- **screen:** Kick result
- **when:** Result banner when a GOOD kick is also down the middle.
- **current:** "DOWN THE MIDDLE!"
- **kind:** static
- **source:** code

### `result_good`
- **screen:** Kick result
- **when:** Large result word. A shank still ends as one of these. There is no result word SHANK.
- **current:** "GOOD"
- **kind:** static
- **source:** code

### `result_short`
- **screen:** Kick result
- **when:** Large result word. A shank still ends as one of these. There is no result word SHANK.
- **current:** "SHORT"
- **kind:** static
- **source:** code

### `result_wide_left`
- **screen:** Kick result
- **when:** Large result word. A shank still ends as one of these. There is no result word SHANK.
- **current:** "WIDE LEFT"
- **kind:** static
- **source:** code

### `result_wide_right`
- **screen:** Kick result
- **when:** Large result word. A shank still ends as one of these. There is no result word SHANK.
- **current:** "WIDE RIGHT"
- **kind:** static
- **source:** code

### `result_doink`
- **screen:** Kick result
- **when:** Large result word. A shank still ends as one of these. There is no result word SHANK.
- **current:** "DOINK"
- **kind:** static
- **source:** code

### `result_score_line`
- **screen:** Kick result
- **when:** Under the result word on a make. Optional pieces, in this order, are inserted only when they apply: " + {storm} wind", " + {hero} hero", " + {curse} curse", " + {drill} drill", " + {pre} pre", then a closing parenthesis, then " × 2" for down the middle, " × 1.5" for a boss, and " (+5 PERFECT)" for a perfect kick. {pre} also covers the Gelcap bonus.
- **current:** "{yards} yd × {mult} = {points}"
- **kind:** template
- **source:** code

### `result_attempt_earned`
- **screen:** Kick result
- **when:** Under the score line when the make earns an attempt.
- **current:** "+1 ATTEMPT"
- **kind:** static
- **source:** code

### `result_attempt_cap`
- **screen:** Kick result
- **when:** Under the score line when a make would earn an attempt but the cap is already full.
- **current:** "AT CAP"
- **kind:** static
- **source:** code

### `result_detail`
- **screen:** Kick result
- **when:** Bottom line of a normal result. {power}, {max_range}, and {kick_distance} are numbers. {result} is GOOD, SHORT, WIDE LEFT, WIDE RIGHT, or DOINK.
- **current:** "P = {power}, max range = {max_range} yd, kick = {kick_distance} yd, result = {result}"
- **kind:** template
- **source:** code

### `result_detail_shank`
- **screen:** Kick result
- **when:** Bottom line when the power needle reaches MAX with no second press. The large result word is still GOOD, SHORT, WIDE LEFT, WIDE RIGHT, or DOINK.
- **current:** "SHANK, full power, max range = {max_range} yd, kick = {kick_distance} yd, result = {result}"
- **kind:** template
- **source:** code

## Loadout offer

### `offer_empty`
- **screen:** Loadout offer
- **when:** When a reroll or a roll leaves no cards.
- **current:** "Nothing left to pick — press S to continue."
- **kind:** static
- **source:** code

### `offer_reroll_line`
- **screen:** Loadout offer
- **when:** Under the cards. {rerolls_left} is the remaining count. {offer_reroll} defaults to R. {skip} defaults to S.
- **current:** "Reroll: {rerolls_left} left    {offer_reroll} rerolls    {skip} skips"
- **kind:** template
- **source:** code

### `offer_skip_hint`
- **screen:** Loadout offer
- **when:** Under the reroll line.
- **current:** "Skip takes nothing."
- **kind:** static
- **source:** code

### `offer_type_line`
- **screen:** Loadout offer
- **when:** Top of a card. {slot_number} is 1, 2, or 3. {type_label} is CLEATS, HELMET, GLOVES, PERK, or CURSE.
- **current:** "{slot_number}  {type_label}"
- **kind:** template
- **source:** code

### `offer_type_cleats`
- **screen:** Loadout offer
- **when:** Type label on an offer card.
- **current:** "CLEATS"
- **kind:** static
- **source:** code

### `offer_type_helmet`
- **screen:** Loadout offer
- **when:** Type label on an offer card.
- **current:** "HELMET"
- **kind:** static
- **source:** code

### `offer_type_gloves`
- **screen:** Loadout offer
- **when:** Type label on an offer card.
- **current:** "GLOVES"
- **kind:** static
- **source:** code

### `offer_type_perk`
- **screen:** Loadout offer
- **when:** Type label on an offer card.
- **current:** "PERK"
- **kind:** static
- **source:** code

### `offer_type_curse`
- **screen:** Loadout offer
- **when:** Type label on an offer card.
- **current:** "CURSE"
- **kind:** static
- **source:** code

### `offer_card_title`
- **screen:** Loadout offer
- **when:** Card title for equipment and perks. {rank_roman} is one of I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII. Standard equipment stops at VI and standard perks stop at III. Endless can reach XII for equipment and VI for perks. Curses omit the roman and show the piece name alone.
- **current:** "{piece_name} {rank_roman}"
- **kind:** template
- **source:** code

### `offer_rank_badge`
- **screen:** Loadout offer
- **when:** Roman numeral in the corner badge of an equipment or perk icon, on the offer and on the top loadout rail. Curses and empty slots have no badge. Values: I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII.
- **current:** "{rank_roman}"
- **kind:** template
- **source:** code

### `offer_missing_icon_word`
- **screen:** Loadout offer
- **when:** First word drawn inside an offer icon when that item has no sprite. Drive Lid has no sprite, so the icon shows the first word of Drive Lid.
- **current:** "Drive"
- **kind:** static
- **source:** code

### `offer_name_cannon_cleats`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Cannon Cleats"
- **kind:** static
- **source:** code

### `offer_name_pinpoint_cleats`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Pinpoint Cleats"
- **kind:** static
- **source:** code

### `offer_name_anchor_cleats`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Anchor Cleats"
- **kind:** static
- **source:** code

### `offer_name_sticker_cleats`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Sticker Cleats"
- **kind:** static
- **source:** code

### `offer_name_wind_visor`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Wind Visor"
- **kind:** static
- **source:** code

### `offer_name_drive_lid`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Drive Lid"
- **kind:** static
- **source:** code

### `offer_name_ice_cage`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Ice Cage"
- **kind:** static
- **source:** code

### `offer_name_scout_lid`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Scout Lid"
- **kind:** static
- **source:** code

### `offer_name_doink_cap`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Doink Cap"
- **kind:** static
- **source:** code

### `offer_name_iron_grip`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Iron Grip"
- **kind:** static
- **source:** code

### `offer_name_replay_gloves`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Replay Gloves"
- **kind:** static
- **source:** code

### `offer_name_high_air_gloves`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "High-Air Gloves"
- **kind:** static
- **source:** code

### `offer_name_weather_wraps`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Weather Wraps"
- **kind:** static
- **source:** code

### `offer_name_deep_bench`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Deep Bench"
- **kind:** static
- **source:** code

### `offer_name_hot_streak`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Hot Streak"
- **kind:** static
- **source:** code

### `offer_name_storm_chaser`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Storm Chaser"
- **kind:** static
- **source:** code

### `offer_name_hero_ball`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Hero Ball"
- **kind:** static
- **source:** code

### `offer_name_glass_leg`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Glass Leg"
- **kind:** static
- **source:** code

### `offer_name_two_minute_drill`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Two-Minute Drill"
- **kind:** static
- **source:** code

### `offer_name_iced`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Iced"
- **kind:** static
- **source:** code

### `offer_name_shanky_cleats`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Shanky Cleats"
- **kind:** static
- **source:** code

### `offer_name_heavy_ball`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Heavy Ball"
- **kind:** static
- **source:** code

### `offer_name_howling_wind`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Howling Wind"
- **kind:** static
- **source:** code

### `offer_name_shaky_arrow`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Shaky Arrow"
- **kind:** static
- **source:** code

### `offer_name_narrow_posts`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Narrow Posts"
- **kind:** static
- **source:** code

### `offer_name_stone_toe`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Stone Toe"
- **kind:** static
- **source:** code

### `offer_name_tight_window`
- **screen:** Loadout offer
- **when:** Piece name on an offer card, alone for a curse and inside the title for equipment and perks.
- **current:** "Tight Window"
- **kind:** static
- **source:** code

### `offer_effect_cannon_cleats_yards`
- **screen:** Loadout offer
- **when:** Cannon Cleats, every rank. {yards} is 6 times the rank. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+{yards} yd"
- **kind:** template
- **source:** code

### `offer_effect_pinpoint_bands`
- **screen:** Loadout offer
- **when:** Pinpoint Cleats, every rank. {perfect_add} is 2 times the rank. {good_add} is 3 times the rank. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "PERFECT +{perfect_add}, good +{good_add}"
- **kind:** template
- **source:** code

### `offer_effect_anchor_needles`
- **screen:** Loadout offer
- **when:** Anchor Cleats, every rank. {factor} is 0.85 to the power of the rank. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Needles ×{factor}"
- **kind:** template
- **source:** code

### `offer_effect_sticker_drift`
- **screen:** Loadout offer
- **when:** Sticker Cleats, every rank. {factor} is 0.80 to the power of the rank. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Drift ×{factor}"
- **kind:** template
- **source:** code

### `offer_effect_drive_lid_yards`
- **screen:** Loadout offer
- **when:** Drive Lid, every rank. {yards} is 4 times the rank. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+{yards} yd"
- **kind:** template
- **source:** code

### `offer_effect_wind_visor_1`
- **screen:** Loadout offer
- **when:** Wind Visor rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Shows wind mph and an arrow"
- **kind:** static
- **source:** code

### `offer_effect_wind_visor_partial`
- **screen:** Loadout offer
- **when:** Wind Visor ranks II through V. {percent} is 40 at II, 55 at III, 70 at IV, and 85 at V. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Dotted path for {percent}% of this kick"
- **kind:** template
- **source:** code

### `offer_effect_wind_visor_full`
- **screen:** Loadout offer
- **when:** Wind Visor rank VI, and Endless ranks VII through XII. The path percent caps at 100. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Dotted path for the full flight"
- **kind:** static
- **source:** code

### `offer_effect_ice_cage_1`
- **screen:** Loadout offer
- **when:** Ice Cage rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "No red-tip penalty. Immune to Iced."
- **kind:** static
- **source:** code

### `offer_effect_ice_cage_2`
- **screen:** Loadout offer
- **when:** Ice Cage rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Also accuracy needle ×0.90"
- **kind:** static
- **source:** code

### `offer_effect_ice_cage_3`
- **screen:** Loadout offer
- **when:** Ice Cage rank III. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Also PERFECT +1"
- **kind:** static
- **source:** code

### `offer_effect_ice_cage_4`
- **screen:** Loadout offer
- **when:** Ice Cage rank IV. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Also good +2"
- **kind:** static
- **source:** code

### `offer_effect_ice_cage_5`
- **screen:** Loadout offer
- **when:** Ice Cage rank V. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "PERFECT +2 total"
- **kind:** static
- **source:** code

### `offer_effect_ice_cage_6`
- **screen:** Loadout offer
- **when:** Ice Cage rank VI and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Good +4 total"
- **kind:** static
- **source:** code

### `offer_effect_scout_lid_low`
- **screen:** Loadout offer
- **when:** Scout Lid ranks I through III. The word stays singular at 2 and 3. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+{count} reroll"
- **kind:** template
- **source:** code

### `offer_effect_scout_lid_4`
- **screen:** Loadout offer
- **when:** Scout Lid rank IV. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+3 rerolls, and one Practice Swing a quarter"
- **kind:** static
- **source:** code

### `offer_effect_scout_lid_5`
- **screen:** Loadout offer
- **when:** Scout Lid rank V. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+4 rerolls, and one Practice Swing a quarter"
- **kind:** static
- **source:** code

### `offer_effect_scout_lid_6`
- **screen:** Loadout offer
- **when:** Scout Lid rank VI and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+5 rerolls, and two Practice Swings a quarter"
- **kind:** static
- **source:** code

### `offer_effect_doink_cap_low`
- **screen:** Loadout offer
- **when:** Doink Cap ranks I through V. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "{count} doink-to-good a quarter"
- **kind:** template
- **source:** code

### `offer_effect_doink_cap_6`
- **screen:** Loadout offer
- **when:** Doink Cap rank VI and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "5 doink-to-good a quarter, unused carry (max 5)"
- **kind:** static
- **source:** code

### `offer_effect_iron_grip_low`
- **screen:** Loadout offer
- **when:** Iron Grip ranks I and II. {amount} is 2 at I and 4 at II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Red-tip noise −{amount}"
- **kind:** template
- **source:** code

### `offer_effect_iron_grip_3`
- **screen:** Loadout offer
- **when:** Iron Grip rank III. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Noise −4 (min ±1), red tip 3 later"
- **kind:** static
- **source:** code

### `offer_effect_iron_grip_4`
- **screen:** Loadout offer
- **when:** Iron Grip rank IV. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Noise −4 (min ±1), red tip 6 later"
- **kind:** static
- **source:** code

### `offer_effect_iron_grip_5`
- **screen:** Loadout offer
- **when:** Iron Grip rank V. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Noise −4 (min ±1), red tip 9 later"
- **kind:** static
- **source:** code

### `offer_effect_iron_grip_6`
- **screen:** Loadout offer
- **when:** Iron Grip rank VI and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Red tip never triggers"
- **kind:** static
- **source:** code

### `offer_effect_replay_low`
- **screen:** Loadout offer
- **when:** Replay Gloves ranks I through V. The word stays singular. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "{count} practice swing a quarter"
- **kind:** template
- **source:** code

### `offer_effect_replay_6`
- **screen:** Loadout offer
- **when:** Replay Gloves rank VI and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "5 practice swings, unused carry (max 5)"
- **kind:** static
- **source:** code

### `offer_effect_high_air`
- **screen:** Loadout offer
- **when:** High-Air Gloves, every rank. {yards} is 2 times the rank. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+{yards} yd, tailwind range ×1.5"
- **kind:** template
- **source:** code

### `offer_effect_weather_1`
- **screen:** Loadout offer
- **when:** Weather Wraps rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Rain, snow, and mud penalties cut in half"
- **kind:** static
- **source:** code

### `offer_effect_weather_2`
- **screen:** Loadout offer
- **when:** Weather Wraps rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Rain, snow, and mud penalties ignored"
- **kind:** static
- **source:** code

### `offer_effect_weather_3`
- **screen:** Loadout offer
- **when:** Weather Wraps rank III. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Also ignores Monsoon's rain and mud"
- **kind:** static
- **source:** code

### `offer_effect_weather_4`
- **screen:** Loadout offer
- **when:** Weather Wraps rank IV. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Penalties ignored, +2 yd unless CLEAR"
- **kind:** static
- **source:** code

### `offer_effect_weather_5`
- **screen:** Loadout offer
- **when:** Weather Wraps rank V. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Penalties ignored, +4 yd unless CLEAR"
- **kind:** static
- **source:** code

### `offer_effect_weather_6`
- **screen:** Loadout offer
- **when:** Weather Wraps rank VI and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Penalties ignored, +6 yd unless CLEAR"
- **kind:** static
- **source:** code

### `offer_effect_deep_bench_low`
- **screen:** Loadout offer
- **when:** Deep Bench ranks I and II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Attempt cap +{count} and attempts +{count}"
- **kind:** template
- **source:** code

### `offer_effect_deep_bench_high`
- **screen:** Loadout offer
- **when:** Deep Bench rank III and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Cap stays. +1 attempt now and each quarter if below cap"
- **kind:** static
- **source:** code

### `offer_effect_hot_streak_1`
- **screen:** Loadout offer
- **when:** Hot Streak rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Streak step +0.5"
- **kind:** static
- **source:** code

### `offer_effect_hot_streak_2`
- **screen:** Loadout offer
- **when:** Hot Streak rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Streak step +0.75"
- **kind:** static
- **source:** code

### `offer_effect_hot_streak_3`
- **screen:** Loadout offer
- **when:** Hot Streak rank III and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Streak step +1.0"
- **kind:** static
- **source:** code

### `offer_effect_storm_1`
- **screen:** Loadout offer
- **when:** Storm Chaser rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+0.2 Mult per mph of crosswind"
- **kind:** static
- **source:** code

### `offer_effect_storm_2`
- **screen:** Loadout offer
- **when:** Storm Chaser rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+0.4 Mult per mph of crosswind"
- **kind:** static
- **source:** code

### `offer_effect_storm_3`
- **screen:** Loadout offer
- **when:** Storm Chaser rank III and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+0.6 Mult per mph of crosswind"
- **kind:** static
- **source:** code

### `offer_effect_hero_1`
- **screen:** Loadout offer
- **when:** Hero Ball rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+1.0 Mult, both needles ×0.80"
- **kind:** static
- **source:** code

### `offer_effect_hero_2`
- **screen:** Loadout offer
- **when:** Hero Ball rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+1.5 Mult, both needles ×0.80"
- **kind:** static
- **source:** code

### `offer_effect_hero_3`
- **screen:** Loadout offer
- **when:** Hero Ball rank III and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+2.0 Mult, both needles ×0.80"
- **kind:** static
- **source:** code

### `offer_effect_glass_1`
- **screen:** Loadout offer
- **when:** Glass Leg rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+8 yd, attempt cap −1"
- **kind:** static
- **source:** code

### `offer_effect_glass_2`
- **screen:** Loadout offer
- **when:** Glass Leg rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+16 yd total, no extra cap loss"
- **kind:** static
- **source:** code

### `offer_effect_glass_3`
- **screen:** Loadout offer
- **when:** Glass Leg rank III and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "+24 yd total, no extra cap loss"
- **kind:** static
- **source:** code

### `offer_effect_drill_1`
- **screen:** Loadout offer
- **when:** Two-Minute Drill rank I. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Boss kicks +0.5 Mult, on top of ×1.5"
- **kind:** static
- **source:** code

### `offer_effect_drill_2`
- **screen:** Loadout offer
- **when:** Two-Minute Drill rank II. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Boss kicks +1.0 Mult, on top of ×1.5"
- **kind:** static
- **source:** code

### `offer_effect_drill_3`
- **screen:** Loadout offer
- **when:** Two-Minute Drill rank III and above. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Boss kicks +1.5 Mult, on top of ×1.5"
- **kind:** static
- **source:** code

### `offer_effect_curse_iced`
- **screen:** Loadout offer
- **when:** Iced curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: meter hides 0.4s after Space. Up: +0.5 Mult"
- **kind:** static
- **source:** code

### `offer_effect_curse_shanky`
- **screen:** Loadout offer
- **when:** Shanky Cleats curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: accuracy error ×1.5. Up: +0.5 Mult"
- **kind:** static
- **source:** code

### `offer_effect_curse_heavy`
- **screen:** Loadout offer
- **when:** Heavy Ball curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: −4 yd. Up: accuracy error ×0.85"
- **kind:** static
- **source:** code

### `offer_effect_curse_howling`
- **screen:** Loadout offer
- **when:** Howling Wind curse card. The in-kick banner uses a different sentence. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: wind ×1.5. Up: equipment and perks ×1.15"
- **kind:** static
- **source:** code

### `offer_effect_curse_shaky`
- **screen:** Loadout offer
- **when:** Shaky Arrow curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: aim sways ±3°. Up: +6 yd"
- **kind:** static
- **source:** code

### `offer_effect_curse_narrow`
- **screen:** Loadout offer
- **when:** Narrow Posts curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: posts 5.17 yd. Up: +0.5 Mult"
- **kind:** static
- **source:** code

### `offer_effect_curse_stone`
- **screen:** Loadout offer
- **when:** Stone Toe curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: power needle ×1.20. Up: +6 yd"
- **kind:** static
- **source:** code

### `offer_effect_curse_tight`
- **screen:** Loadout offer
- **when:** Tight Window curse card. Same words on the loadout-rail tooltip; that copy is listed again below.
- **current:** "Down: PERFECT and good −2. Up: +0.5 Mult"
- **kind:** static
- **source:** code

## Loadout rail tooltip

### `rail_missing_icon_word`
- **screen:** Loadout rail tooltip
- **when:** First word drawn inside the top-rail icon when that item has no sprite. Drive Lid has no sprite, so the rail icon shows the first word of Drive Lid. The tooltip itself still uses the full name.
- **current:** "Drive"
- **kind:** static
- **source:** code

### `tooltip_empty_cleats`
- **screen:** Loadout rail tooltip
- **when:** Hover or pinned tooltip on an empty rail slot. Empty perk slots draw a box and no icon text. There is no empty_perk.png.
- **current:** "Cleats"
- **kind:** static
- **source:** code

### `tooltip_empty_helmet`
- **screen:** Loadout rail tooltip
- **when:** Hover or pinned tooltip on an empty rail slot. Empty perk slots draw a box and no icon text. There is no empty_perk.png.
- **current:** "Helmet"
- **kind:** static
- **source:** code

### `tooltip_empty_gloves`
- **screen:** Loadout rail tooltip
- **when:** Hover or pinned tooltip on an empty rail slot. Empty perk slots draw a box and no icon text. There is no empty_perk.png.
- **current:** "Gloves"
- **kind:** static
- **source:** code

### `tooltip_empty_perk`
- **screen:** Loadout rail tooltip
- **when:** Hover or pinned tooltip on an empty rail slot. Empty perk slots draw a box and no icon text. There is no empty_perk.png.
- **current:** "Perk"
- **kind:** static
- **source:** code

### `tooltip_empty_curse`
- **screen:** Loadout rail tooltip
- **when:** Hover or pinned tooltip on an empty rail slot. Empty perk slots draw a box and no icon text. There is no empty_perk.png.
- **current:** "Curse"
- **kind:** static
- **source:** code

### `tooltip_title`
- **screen:** Loadout rail tooltip
- **when:** First tooltip line for a filled equipment or perk slot. {rank_roman} is I through XII, as on the offer. A curse tooltip is the piece name with no roman.
- **current:** "{piece_name} {rank_roman}"
- **kind:** template
- **source:** code

### `tooltip_name_cannon_cleats`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Cannon Cleats"
- **kind:** static
- **source:** code

### `tooltip_name_pinpoint_cleats`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Pinpoint Cleats"
- **kind:** static
- **source:** code

### `tooltip_name_anchor_cleats`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Anchor Cleats"
- **kind:** static
- **source:** code

### `tooltip_name_sticker_cleats`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Sticker Cleats"
- **kind:** static
- **source:** code

### `tooltip_name_wind_visor`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Wind Visor"
- **kind:** static
- **source:** code

### `tooltip_name_drive_lid`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Drive Lid"
- **kind:** static
- **source:** code

### `tooltip_name_ice_cage`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Ice Cage"
- **kind:** static
- **source:** code

### `tooltip_name_scout_lid`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Scout Lid"
- **kind:** static
- **source:** code

### `tooltip_name_doink_cap`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Doink Cap"
- **kind:** static
- **source:** code

### `tooltip_name_iron_grip`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Iron Grip"
- **kind:** static
- **source:** code

### `tooltip_name_replay_gloves`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Replay Gloves"
- **kind:** static
- **source:** code

### `tooltip_name_high_air_gloves`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "High-Air Gloves"
- **kind:** static
- **source:** code

### `tooltip_name_weather_wraps`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Weather Wraps"
- **kind:** static
- **source:** code

### `tooltip_name_deep_bench`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Deep Bench"
- **kind:** static
- **source:** code

### `tooltip_name_hot_streak`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Hot Streak"
- **kind:** static
- **source:** code

### `tooltip_name_storm_chaser`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Storm Chaser"
- **kind:** static
- **source:** code

### `tooltip_name_hero_ball`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Hero Ball"
- **kind:** static
- **source:** code

### `tooltip_name_glass_leg`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Glass Leg"
- **kind:** static
- **source:** code

### `tooltip_name_two_minute_drill`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Two-Minute Drill"
- **kind:** static
- **source:** code

### `tooltip_name_iced`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Iced"
- **kind:** static
- **source:** code

### `tooltip_name_shanky_cleats`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Shanky Cleats"
- **kind:** static
- **source:** code

### `tooltip_name_heavy_ball`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Heavy Ball"
- **kind:** static
- **source:** code

### `tooltip_name_howling_wind`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Howling Wind"
- **kind:** static
- **source:** code

### `tooltip_name_shaky_arrow`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Shaky Arrow"
- **kind:** static
- **source:** code

### `tooltip_name_narrow_posts`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Narrow Posts"
- **kind:** static
- **source:** code

### `tooltip_name_stone_toe`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Stone Toe"
- **kind:** static
- **source:** code

### `tooltip_name_tight_window`
- **screen:** Loadout rail tooltip
- **when:** Piece name in the rail tooltip.
- **current:** "Tight Window"
- **kind:** static
- **source:** code

### `tooltip_effect_cannon_cleats_yards`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Cannon Cleats, every rank. {yards} is 6 times the rank.
- **current:** "+{yards} yd"
- **kind:** template
- **source:** code

### `tooltip_effect_pinpoint_bands`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Pinpoint Cleats, every rank. {perfect_add} is 2 times the rank. {good_add} is 3 times the rank.
- **current:** "PERFECT +{perfect_add}, good +{good_add}"
- **kind:** template
- **source:** code

### `tooltip_effect_anchor_needles`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Anchor Cleats, every rank. {factor} is 0.85 to the power of the rank.
- **current:** "Needles ×{factor}"
- **kind:** template
- **source:** code

### `tooltip_effect_sticker_drift`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Sticker Cleats, every rank. {factor} is 0.80 to the power of the rank.
- **current:** "Drift ×{factor}"
- **kind:** template
- **source:** code

### `tooltip_effect_drive_lid_yards`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Drive Lid, every rank. {yards} is 4 times the rank.
- **current:** "+{yards} yd"
- **kind:** template
- **source:** code

### `tooltip_effect_wind_visor_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Wind Visor rank I.
- **current:** "Shows wind mph and an arrow"
- **kind:** static
- **source:** code

### `tooltip_effect_wind_visor_partial`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Wind Visor ranks II through V. {percent} is 40 at II, 55 at III, 70 at IV, and 85 at V.
- **current:** "Dotted path for {percent}% of this kick"
- **kind:** template
- **source:** code

### `tooltip_effect_wind_visor_full`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Wind Visor rank VI, and Endless ranks VII through XII. The path percent caps at 100.
- **current:** "Dotted path for the full flight"
- **kind:** static
- **source:** code

### `tooltip_effect_ice_cage_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Ice Cage rank I.
- **current:** "No red-tip penalty. Immune to Iced."
- **kind:** static
- **source:** code

### `tooltip_effect_ice_cage_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Ice Cage rank II.
- **current:** "Also accuracy needle ×0.90"
- **kind:** static
- **source:** code

### `tooltip_effect_ice_cage_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Ice Cage rank III.
- **current:** "Also PERFECT +1"
- **kind:** static
- **source:** code

### `tooltip_effect_ice_cage_4`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Ice Cage rank IV.
- **current:** "Also good +2"
- **kind:** static
- **source:** code

### `tooltip_effect_ice_cage_5`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Ice Cage rank V.
- **current:** "PERFECT +2 total"
- **kind:** static
- **source:** code

### `tooltip_effect_ice_cage_6`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Ice Cage rank VI and above.
- **current:** "Good +4 total"
- **kind:** static
- **source:** code

### `tooltip_effect_scout_lid_low`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Scout Lid ranks I through III. The word stays singular at 2 and 3.
- **current:** "+{count} reroll"
- **kind:** template
- **source:** code

### `tooltip_effect_scout_lid_4`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Scout Lid rank IV.
- **current:** "+3 rerolls, and one Practice Swing a quarter"
- **kind:** static
- **source:** code

### `tooltip_effect_scout_lid_5`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Scout Lid rank V.
- **current:** "+4 rerolls, and one Practice Swing a quarter"
- **kind:** static
- **source:** code

### `tooltip_effect_scout_lid_6`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Scout Lid rank VI and above.
- **current:** "+5 rerolls, and two Practice Swings a quarter"
- **kind:** static
- **source:** code

### `tooltip_effect_doink_cap_low`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Doink Cap ranks I through V.
- **current:** "{count} doink-to-good a quarter"
- **kind:** template
- **source:** code

### `tooltip_effect_doink_cap_6`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Doink Cap rank VI and above.
- **current:** "5 doink-to-good a quarter, unused carry (max 5)"
- **kind:** static
- **source:** code

### `tooltip_effect_iron_grip_low`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Iron Grip ranks I and II. {amount} is 2 at I and 4 at II.
- **current:** "Red-tip noise −{amount}"
- **kind:** template
- **source:** code

### `tooltip_effect_iron_grip_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Iron Grip rank III.
- **current:** "Noise −4 (min ±1), red tip 3 later"
- **kind:** static
- **source:** code

### `tooltip_effect_iron_grip_4`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Iron Grip rank IV.
- **current:** "Noise −4 (min ±1), red tip 6 later"
- **kind:** static
- **source:** code

### `tooltip_effect_iron_grip_5`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Iron Grip rank V.
- **current:** "Noise −4 (min ±1), red tip 9 later"
- **kind:** static
- **source:** code

### `tooltip_effect_iron_grip_6`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Iron Grip rank VI and above.
- **current:** "Red tip never triggers"
- **kind:** static
- **source:** code

### `tooltip_effect_replay_low`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Replay Gloves ranks I through V. The word stays singular.
- **current:** "{count} practice swing a quarter"
- **kind:** template
- **source:** code

### `tooltip_effect_replay_6`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Replay Gloves rank VI and above.
- **current:** "5 practice swings, unused carry (max 5)"
- **kind:** static
- **source:** code

### `tooltip_effect_high_air`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. High-Air Gloves, every rank. {yards} is 2 times the rank.
- **current:** "+{yards} yd, tailwind range ×1.5"
- **kind:** template
- **source:** code

### `tooltip_effect_weather_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Weather Wraps rank I.
- **current:** "Rain, snow, and mud penalties cut in half"
- **kind:** static
- **source:** code

### `tooltip_effect_weather_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Weather Wraps rank II.
- **current:** "Rain, snow, and mud penalties ignored"
- **kind:** static
- **source:** code

### `tooltip_effect_weather_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Weather Wraps rank III.
- **current:** "Also ignores Monsoon's rain and mud"
- **kind:** static
- **source:** code

### `tooltip_effect_weather_4`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Weather Wraps rank IV.
- **current:** "Penalties ignored, +2 yd unless CLEAR"
- **kind:** static
- **source:** code

### `tooltip_effect_weather_5`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Weather Wraps rank V.
- **current:** "Penalties ignored, +4 yd unless CLEAR"
- **kind:** static
- **source:** code

### `tooltip_effect_weather_6`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Weather Wraps rank VI and above.
- **current:** "Penalties ignored, +6 yd unless CLEAR"
- **kind:** static
- **source:** code

### `tooltip_effect_deep_bench_low`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Deep Bench ranks I and II.
- **current:** "Attempt cap +{count} and attempts +{count}"
- **kind:** template
- **source:** code

### `tooltip_effect_deep_bench_high`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Deep Bench rank III and above.
- **current:** "Cap stays. +1 attempt now and each quarter if below cap"
- **kind:** static
- **source:** code

### `tooltip_effect_hot_streak_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Hot Streak rank I.
- **current:** "Streak step +0.5"
- **kind:** static
- **source:** code

### `tooltip_effect_hot_streak_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Hot Streak rank II.
- **current:** "Streak step +0.75"
- **kind:** static
- **source:** code

### `tooltip_effect_hot_streak_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Hot Streak rank III and above.
- **current:** "Streak step +1.0"
- **kind:** static
- **source:** code

### `tooltip_effect_storm_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Storm Chaser rank I.
- **current:** "+0.2 Mult per mph of crosswind"
- **kind:** static
- **source:** code

### `tooltip_effect_storm_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Storm Chaser rank II.
- **current:** "+0.4 Mult per mph of crosswind"
- **kind:** static
- **source:** code

### `tooltip_effect_storm_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Storm Chaser rank III and above.
- **current:** "+0.6 Mult per mph of crosswind"
- **kind:** static
- **source:** code

### `tooltip_effect_hero_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Hero Ball rank I.
- **current:** "+1.0 Mult, both needles ×0.80"
- **kind:** static
- **source:** code

### `tooltip_effect_hero_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Hero Ball rank II.
- **current:** "+1.5 Mult, both needles ×0.80"
- **kind:** static
- **source:** code

### `tooltip_effect_hero_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Hero Ball rank III and above.
- **current:** "+2.0 Mult, both needles ×0.80"
- **kind:** static
- **source:** code

### `tooltip_effect_glass_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Glass Leg rank I.
- **current:** "+8 yd, attempt cap −1"
- **kind:** static
- **source:** code

### `tooltip_effect_glass_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Glass Leg rank II.
- **current:** "+16 yd total, no extra cap loss"
- **kind:** static
- **source:** code

### `tooltip_effect_glass_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Glass Leg rank III and above.
- **current:** "+24 yd total, no extra cap loss"
- **kind:** static
- **source:** code

### `tooltip_effect_drill_1`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Two-Minute Drill rank I.
- **current:** "Boss kicks +0.5 Mult, on top of ×1.5"
- **kind:** static
- **source:** code

### `tooltip_effect_drill_2`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Two-Minute Drill rank II.
- **current:** "Boss kicks +1.0 Mult, on top of ×1.5"
- **kind:** static
- **source:** code

### `tooltip_effect_drill_3`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Two-Minute Drill rank III and above.
- **current:** "Boss kicks +1.5 Mult, on top of ×1.5"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_iced`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Iced curse card.
- **current:** "Down: meter hides 0.4s after Space. Up: +0.5 Mult"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_shanky`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Shanky Cleats curse card.
- **current:** "Down: accuracy error ×1.5. Up: +0.5 Mult"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_heavy`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Heavy Ball curse card.
- **current:** "Down: −4 yd. Up: accuracy error ×0.85"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_howling`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Howling Wind curse card. The in-kick banner uses a different sentence.
- **current:** "Down: wind ×1.5. Up: equipment and perks ×1.15"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_shaky`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Shaky Arrow curse card.
- **current:** "Down: aim sways ±3°. Up: +6 yd"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_narrow`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Narrow Posts curse card.
- **current:** "Down: posts 5.17 yd. Up: +0.5 Mult"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_stone`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Stone Toe curse card.
- **current:** "Down: power needle ×1.20. Up: +6 yd"
- **kind:** static
- **source:** code

### `tooltip_effect_curse_tight`
- **screen:** Loadout rail tooltip
- **when:** Rail tooltip. Tight Window curse card.
- **current:** "Down: PERFECT and good −2. Up: +0.5 Mult"
- **kind:** static
- **source:** code

## Vitamin Shop

### `shop_painted_sign`
- **screen:** Vitamin Shop
- **when:** Painted sign on art/shop/vitamin_shop.png. Shelf bottle labels are blank or not readable words.
- **current:** "VITAMINS"
- **kind:** static
- **source:** painted

### `shop_title`
- **screen:** Vitamin Shop
- **when:** Code title at the upper left, over the shop backdrop.
- **current:** "VITAMIN SHOP"
- **kind:** static
- **source:** code

### `shop_cash`
- **screen:** Vitamin Shop
- **when:** Cash on the shop info plate.
- **current:** "${cash}"
- **kind:** template
- **source:** code

### `shop_cash_popup`
- **screen:** Vitamin Shop
- **when:** Beside the shop cash when a popup is active.
- **current:** "+${amount}"
- **kind:** template
- **source:** code

### `shop_next_boss_squeeze`
- **screen:** Vitamin Shop
- **when:** On the shop info plate after kick 5 in Standard.
- **current:** "Next boss: The Squeeze"
- **kind:** static
- **source:** code

### `shop_next_boss_monsoon`
- **screen:** Vitamin Shop
- **when:** On the shop info plate after kick 10 in Standard.
- **current:** "Next boss: Monsoon"
- **kind:** static
- **source:** code

### `shop_next_boss_big_game`
- **screen:** Vitamin Shop
- **when:** On the shop info plate after kick 15 in Standard.
- **current:** "Next boss: Big Game"
- **kind:** static
- **source:** code

### `shop_next_boss_endless`
- **screen:** Vitamin Shop
- **when:** On the shop info plate in Endless after kick 5 (boss at 10) or after kicks 10 and 15 (boss at 20). {boss_name} is Iced, The Squeeze, Monsoon, or Big Game. Other shop visits leave this line blank.
- **current:** "Next boss: {boss_name}"
- **kind:** template
- **source:** code

### `shop_boss_iced`
- **screen:** Vitamin Shop
- **when:** Boss name that can be inserted into the Endless next-boss line. Case differs from the in-kick weather name.
- **current:** "Iced"
- **kind:** static
- **source:** code

### `shop_boss_squeeze`
- **screen:** Vitamin Shop
- **when:** Boss name that can be inserted into the Endless next-boss line. Case differs from the in-kick weather name.
- **current:** "The Squeeze"
- **kind:** static
- **source:** code

### `shop_boss_monsoon`
- **screen:** Vitamin Shop
- **when:** Boss name that can be inserted into the Endless next-boss line. Case differs from the in-kick weather name.
- **current:** "Monsoon"
- **kind:** static
- **source:** code

### `shop_boss_big_game`
- **screen:** Vitamin Shop
- **when:** Boss name that can be inserted into the Endless next-boss line. Case differs from the in-kick weather name.
- **current:** "Big Game"
- **kind:** static
- **source:** code

### `shop_belt_z`
- **screen:** Vitamin Shop
- **when:** Shop belt slot label. Written as Z.
- **current:** "Z"
- **kind:** static
- **source:** code

### `shop_belt_x`
- **screen:** Vitamin Shop
- **when:** Shop belt slot label. Written as X.
- **current:** "X"
- **kind:** static
- **source:** code

### `shop_belt_name`
- **screen:** Vitamin Shop
- **when:** Pattern for a vitamin name on a filled shop belt slot. The exact names are the shelf names listed below.
- **current:** "{vitamin_name}"
- **kind:** template
- **source:** code

### `shop_sold`
- **screen:** Vitamin Shop
- **when:** On an empty shelf slot after that bottle is bought.
- **current:** "SOLD"
- **kind:** static
- **source:** code

### `shop_price_line`
- **screen:** Vitamin Shop
- **when:** On a stocked shelf plate. {slot_number} is 1, 2, or 3. A price the player cannot afford turns red and adds no words.
- **current:** "{slot_number}  ${price}"
- **kind:** template
- **source:** code

### `shop_reroll`
- **screen:** Vitamin Shop
- **when:** Under the shop title. {shop_reroll} defaults to F. The price starts at 2 and rises by 1 after each buy. Too little cash turns it red and adds no words.
- **current:** "Reroll ({shop_reroll}): ${price}"
- **kind:** template
- **source:** code

### `shop_belt_full`
- **screen:** Vitamin Shop
- **when:** Under the reroll line when a buy is refused because both belt slots are full.
- **current:** "Belt full: sell first"
- **kind:** static
- **source:** code

### `shop_footer`
- **screen:** Vitamin Shop
- **when:** Bottom of the shop. Defaults: 1, 2, and 3 buy, 4 for B12, Z and X sell, F rerolls, SPACE leaves. These follow Options.
- **current:** "{choose_1}/{choose_2}/{choose_3} buy  {buy_b12} B12  {belt_z}/{belt_x} sell  {shop_reroll} reroll  {confirm} leave"
- **kind:** template
- **source:** code

### `shop_b12_title`
- **screen:** Vitamin Shop
- **when:** B12 plate title. {buy_b12} defaults to 4.
- **current:** "{buy_b12}  B12 Shot"
- **kind:** template
- **source:** code

### `shop_b12_price`
- **screen:** Vitamin Shop
- **when:** Price on the B12 plate. Red when it cannot be bought. No extra words for being short on cash.
- **current:** "${price}"
- **kind:** template
- **source:** code

### `shop_b12_sold`
- **screen:** Vitamin Shop
- **when:** On the B12 plate after it is bought this visit.
- **current:** "SOLD"
- **kind:** static
- **source:** code

### `shop_b12_at_cap`
- **screen:** Vitamin Shop
- **when:** On the B12 plate when attempts are already at the cap and it has not been bought.
- **current:** "At cap"
- **kind:** static
- **source:** code

### `shop_name_protein_shake`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Protein Shake"
- **kind:** static
- **source:** code

### `shop_effect_protein_shake`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "+6 yd this kick"
- **kind:** static
- **source:** code

### `shop_belt_name_protein_shake`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Protein Shake"
- **kind:** static
- **source:** code

### `shop_name_magnesium`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Magnesium"
- **kind:** static
- **source:** code

### `shop_effect_magnesium`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Needles ×0.7 this kick"
- **kind:** static
- **source:** code

### `shop_belt_name_magnesium`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Magnesium"
- **kind:** static
- **source:** code

### `shop_name_omega_3`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Omega-3"
- **kind:** static
- **source:** code

### `shop_effect_omega_3`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Good band wipes the angle error"
- **kind:** static
- **source:** code

### `shop_belt_name_omega_3`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Omega-3"
- **kind:** static
- **source:** code

### `shop_name_electrolyte_tabs`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Electrolyte Tabs"
- **kind:** static
- **source:** code

### `shop_effect_electrolyte_tabs`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "A miss keeps the attempt"
- **kind:** static
- **source:** code

### `shop_belt_name_electrolyte_tabs`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Electrolyte Tabs"
- **kind:** static
- **source:** code

### `shop_name_vitamin_d`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Vitamin D"
- **kind:** static
- **source:** code

### `shop_effect_vitamin_d`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Ignore rain, snow, and mud"
- **kind:** static
- **source:** code

### `shop_belt_name_vitamin_d`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Vitamin D"
- **kind:** static
- **source:** code

### `shop_name_pre_workout`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Pre-Workout"
- **kind:** static
- **source:** code

### `shop_effect_pre_workout`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "+0.5 Mult if this kick is made"
- **kind:** static
- **source:** code

### `shop_belt_name_pre_workout`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Pre-Workout"
- **kind:** static
- **source:** code

### `shop_name_zinc`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Zinc"
- **kind:** static
- **source:** code

### `shop_effect_zinc`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Reroll this kick's wind and weather"
- **kind:** static
- **source:** code

### `shop_belt_name_zinc`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Zinc"
- **kind:** static
- **source:** code

### `shop_name_lutein`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Lutein"
- **kind:** static
- **source:** code

### `shop_effect_lutein`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Wind numbers and a full dotted path"
- **kind:** static
- **source:** code

### `shop_belt_name_lutein`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Lutein"
- **kind:** static
- **source:** code

### `shop_name_pickle_juice`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Pickle Juice"
- **kind:** static
- **source:** code

### `shop_effect_pickle_juice`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Sideways wind drift ×0.5"
- **kind:** static
- **source:** code

### `shop_belt_name_pickle_juice`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Pickle Juice"
- **kind:** static
- **source:** code

### `shop_name_tart_cherry`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "Tart Cherry"
- **kind:** static
- **source:** code

### `shop_effect_tart_cherry`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "Remove one curse"
- **kind:** static
- **source:** code

### `shop_belt_name_tart_cherry`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "Tart Cherry"
- **kind:** static
- **source:** code

### `shop_name_b12_shot`
- **screen:** Vitamin Shop
- **when:** Vitamin name on its shelf plate, or on the B12 plate for B12 Shot.
- **current:** "B12 Shot"
- **kind:** static
- **source:** code

### `shop_effect_b12_shot`
- **screen:** Vitamin Shop
- **when:** Effect under the vitamin name, or on the B12 plate for B12 Shot.
- **current:** "+1 attempt"
- **kind:** static
- **source:** code

### `shop_belt_name_b12_shot`
- **screen:** Vitamin Shop
- **when:** Same vitamin name on a filled shop belt slot.
- **current:** "B12 Shot"
- **kind:** static
- **source:** code

## Trophy Room

### `records_title`
- **screen:** Trophy Room
- **when:** Code title at the top of the records screen. Separate from the painted main-menu tile.
- **current:** "TROPHY ROOM"
- **kind:** static
- **source:** code

### `records_back`
- **screen:** Trophy Room
- **when:** Under the title. Written as Esc, not the live BACK / CANCEL bind.
- **current:** "Esc: back"
- **kind:** static
- **source:** code

### `records_lifetime`
- **screen:** Trophy Room
- **when:** Section label for the lifetime numbers.
- **current:** "Lifetime"
- **kind:** static
- **source:** code

### `records_runs_wins`
- **screen:** Trophy Room
- **when:** Lifetime runs and wins.
- **current:** "Runs {runs}    Wins {wins}"
- **kind:** template
- **source:** code

### `records_best_score`
- **screen:** Trophy Room
- **when:** Lifetime best score.
- **current:** "Best score {score}"
- **kind:** template
- **source:** code

### `records_longest`
- **screen:** Trophy Room
- **when:** Lifetime longest make. {distance} is an em dash when it is 0, otherwise "{yards} yd".
- **current:** "Longest make {distance}"
- **kind:** template
- **source:** code

### `records_longest_dash`
- **screen:** Trophy Room
- **when:** Shown in place of a yard number when the longest make is 0, on the lifetime line and on a kicker card.
- **current:** "—"
- **kind:** static
- **source:** code

### `records_longest_yards`
- **screen:** Trophy Room
- **when:** Shown in place of a yard number when the longest make is at least 1.
- **current:** "{yards} yd"
- **kind:** template
- **source:** code

### `records_nfl`
- **screen:** Trophy Room
- **when:** Under the lifetime longest make.
- **current:** "NFL record: 68 yd (Cam Little, 2025)"
- **kind:** static
- **source:** code

### `records_fg`
- **screen:** Trophy Room
- **when:** Lifetime field-goal rate. {rate} is an em dash when there are no attempts, otherwise a number and a percent sign such as 50.0%.
- **current:** "FG% {rate}"
- **kind:** template
- **source:** code

### `records_bruce_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Big Bruce"
- **kind:** static
- **source:** code

### `records_walk_on_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "The Walk-On"
- **kind:** static
- **source:** code

### `records_phil_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Phil The Pharmacist"
- **kind:** static
- **source:** code

### `records_gary_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Gary the Goat"
- **kind:** static
- **source:** code

### `records_vex_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Vex"
- **kind:** static
- **source:** code

### `records_cole_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Cole Lang"
- **kind:** static
- **source:** code

### `records_willow_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Willow Reed"
- **kind:** static
- **source:** code

### `records_carlos_name`
- **screen:** Trophy Room
- **when:** Kicker name on that kicker's record card.
- **current:** "Carlos Hernandez"
- **kind:** static
- **source:** code

### `records_kicker_runs`
- **screen:** Trophy Room
- **when:** On each kicker card.
- **current:** "Runs {runs}    Wins {wins}"
- **kind:** template
- **source:** code

### `records_kicker_best`
- **screen:** Trophy Room
- **when:** On each kicker card. {distance} is the same dash or yard form as the lifetime longest make.
- **current:** "Best {score}    Long {distance}"
- **kind:** template
- **source:** code

### `records_kicker_fg`
- **screen:** Trophy Room
- **when:** On each kicker card. Same rate form as the lifetime FG% line.
- **current:** "FG% {rate}"
- **kind:** template
- **source:** code

### `records_trophies_heading`
- **screen:** Trophy Room
- **when:** Section label above the trophy grid.
- **current:** "Trophies"
- **kind:** static
- **source:** code

### `records_trophy_hidden`
- **screen:** Trophy Room
- **when:** On a trophy that has not been earned. The condition is still written under it.
- **current:** "?"
- **kind:** static
- **source:** code

### `records_trophy_extra_point_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Extra Point"
- **kind:** static
- **source:** code

### `records_trophy_extra_point_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Make any kick"
- **kind:** static
- **source:** code

### `records_trophy_fifty_club_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Fifty Club"
- **kind:** static
- **source:** code

### `records_trophy_fifty_club_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Make a 50+ yard kick"
- **kind:** static
- **source:** code

### `records_trophy_sixty_club_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Sixty Club"
- **kind:** static
- **source:** code

### `records_trophy_sixty_club_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Make a 60+ yard kick"
- **kind:** static
- **source:** code

### `records_trophy_record_breaker_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Record Breaker"
- **kind:** static
- **source:** code

### `records_trophy_record_breaker_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Make a 69+ yard kick"
- **kind:** static
- **source:** code

### `records_trophy_perfect_quarter_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Perfect Quarter"
- **kind:** static
- **source:** code

### `records_trophy_perfect_quarter_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Make all 5 kicks of a quarter on the first ball"
- **kind:** static
- **source:** code

### `records_trophy_hot_hand_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Hot Hand"
- **kind:** static
- **source:** code

### `records_trophy_hot_hand_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Reach a streak of 10"
- **kind:** static
- **source:** code

### `records_trophy_season_complete_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Season Complete"
- **kind:** static
- **source:** code

### `records_trophy_season_complete_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "Make kick 20"
- **kind:** static
- **source:** code

### `records_trophy_bullseye_collector_name`
- **screen:** Trophy Room
- **when:** Name on an earned trophy card. A locked card shows ? instead.
- **current:** "Bullseye Collector"
- **kind:** static
- **source:** code

### `records_trophy_bullseye_collector_condition`
- **screen:** Trophy Room
- **when:** Condition under the trophy, earned or locked.
- **current:** "10 lifetime down-the-middle makes"
- **kind:** static
- **source:** code

## End of run

### `end_game_over`
- **screen:** End of run
- **when:** Title when attempts hit 0.
- **current:** "GAME OVER"
- **kind:** static
- **source:** code

### `end_win`
- **screen:** End of run
- **when:** Title when Standard kick 20 is made.
- **current:** "WIN"
- **kind:** static
- **source:** code

### `end_far`
- **screen:** End of run
- **when:** Title when an Endless kick reaches 1000 yards.
- **current:** "THAT'S FAR ENOUGH"
- **kind:** static
- **source:** code

### `end_score`
- **screen:** End of run
- **when:** Under the end title.
- **current:** "Score {score}"
- **kind:** template
- **source:** code

### `end_new_record_score`
- **screen:** End of run
- **when:** Drawn over the score line when this run set a best score.
- **current:** "NEW RECORD!"
- **kind:** static
- **source:** code

### `end_makes`
- **screen:** End of run
- **when:** Under the score.
- **current:** "Kicks made {makes}"
- **kind:** template
- **source:** code

### `end_longest`
- **screen:** End of run
- **when:** Under the makes.
- **current:** "Longest make {yards} yd"
- **kind:** template
- **source:** code

### `end_new_record_long`
- **screen:** End of run
- **when:** Drawn over the longest-make line when this run set a new longest make.
- **current:** "NEW RECORD!"
- **kind:** static
- **source:** code

### `end_kicker`
- **screen:** End of run
- **when:** Under the longest make, when a kicker was chosen. {kicker_name} is one of the eight names.
- **current:** "Kicker: {kicker_name}"
- **kind:** template
- **source:** code

### `end_loadout`
- **screen:** End of run
- **when:** Under the kicker. {owned} is none when nothing was taken. Otherwise it is card titles separated by a comma and a space, using the same "{piece_name} {rank_roman}" form as the offer. Curses have no roman.
- **current:** "Loadout: {owned}"
- **kind:** template
- **source:** code

### `end_loadout_none`
- **screen:** End of run
- **when:** The owned list when the run took no equipment, perk, or curse.
- **current:** "none"
- **kind:** static
- **source:** code

### `end_footer`
- **screen:** End of run
- **when:** Bottom of the end panel. {trophy} defaults to T. {back} defaults to ESC. The R is written out.
- **current:** "{trophy}: trophy room    {back}: main menu    R: choose a kicker"
- **kind:** template
- **source:** code

## Mulligan overlay

### `mulligan_title`
- **screen:** Mulligan overlay
- **when:** After a miss while a mulligan remains.
- **current:** "Use Mulligan? (M)"
- **kind:** static
- **source:** code

### `mulligan_hint`
- **screen:** Mulligan overlay
- **when:** Under the mulligan title. M and Space are written out.
- **current:** "M retakes this kick.  Space accepts the miss."
- **kind:** static
- **source:** code

## Curse removal overlay

### `curse_prompt_title`
- **screen:** Curse removal overlay
- **when:** After Tart Cherry is used while at least one curse is held.
- **current:** "Remove which curse?"
- **kind:** static
- **source:** code

### `curse_prompt_choices`
- **screen:** Curse removal overlay
- **when:** Choice line. {index} is 1 or 2. Two choices are separated by four spaces.
- **current:** "{index} {curse_name}"
- **kind:** template
- **source:** code

### `curse_prompt_iced`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Iced"
- **kind:** static
- **source:** code

### `curse_prompt_shanky_cleats`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Shanky Cleats"
- **kind:** static
- **source:** code

### `curse_prompt_heavy_ball`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Heavy Ball"
- **kind:** static
- **source:** code

### `curse_prompt_howling_wind`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Howling Wind"
- **kind:** static
- **source:** code

### `curse_prompt_shaky_arrow`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Shaky Arrow"
- **kind:** static
- **source:** code

### `curse_prompt_narrow_posts`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Narrow Posts"
- **kind:** static
- **source:** code

### `curse_prompt_stone_toe`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Stone Toe"
- **kind:** static
- **source:** code

### `curse_prompt_tight_window`
- **screen:** Curse removal overlay
- **when:** Curse name that can appear in the choice line.
- **current:** "Tight Window"
- **kind:** static
- **source:** code

### `curse_prompt_cancel`
- **screen:** Curse removal overlay
- **when:** Under the choice line.
- **current:** "Esc cancels. Tart Cherry stays on the belt."
- **kind:** static
- **source:** code

## Trophy popup

### `trophy_popup`
- **screen:** Trophy popup
- **when:** Banner for about two seconds when a trophy is earned during a kick. {trophy_name} is one of the eight Trophy Room names.
- **current:** "TROPHY: {trophy_name}"
- **kind:** template
- **source:** code

### `trophy_popup_extra_point`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Extra Point"
- **kind:** static
- **source:** code

### `trophy_popup_fifty_club`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Fifty Club"
- **kind:** static
- **source:** code

### `trophy_popup_sixty_club`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Sixty Club"
- **kind:** static
- **source:** code

### `trophy_popup_record_breaker`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Record Breaker"
- **kind:** static
- **source:** code

### `trophy_popup_perfect_quarter`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Perfect Quarter"
- **kind:** static
- **source:** code

### `trophy_popup_hot_hand`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Hot Hand"
- **kind:** static
- **source:** code

### `trophy_popup_season_complete`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Season Complete"
- **kind:** static
- **source:** code

### `trophy_popup_bullseye_collector`
- **screen:** Trophy popup
- **when:** Trophy name that can appear in the popup. Same words as the Trophy Room card.
- **current:** "Bullseye Collector"
- **kind:** static
- **source:** code

## Unlock and save notes

### `unlock_toast`
- **screen:** Unlock and save notes
- **when:** Gold line during play when a kicker unlocks. The six lines that can appear are listed next.
- **current:** "{kicker_name} unlocked"
- **kind:** template
- **source:** code

### `unlock_toast_phil`
- **screen:** Unlock and save notes
- **when:** Unlock line for this kicker.
- **current:** "Phil The Pharmacist unlocked"
- **kind:** static
- **source:** code

### `unlock_toast_gary`
- **screen:** Unlock and save notes
- **when:** Unlock line for this kicker.
- **current:** "Gary the Goat unlocked"
- **kind:** static
- **source:** code

### `unlock_toast_vex`
- **screen:** Unlock and save notes
- **when:** Unlock line for this kicker.
- **current:** "Vex unlocked"
- **kind:** static
- **source:** code

### `unlock_toast_cole`
- **screen:** Unlock and save notes
- **when:** Unlock line for this kicker.
- **current:** "Cole Lang unlocked"
- **kind:** static
- **source:** code

### `unlock_toast_willow`
- **screen:** Unlock and save notes
- **when:** Unlock line for this kicker.
- **current:** "Willow Reed unlocked"
- **kind:** static
- **source:** code

### `unlock_toast_carlos`
- **screen:** Unlock and save notes
- **when:** Unlock line for this kicker.
- **current:** "Carlos Hernandez unlocked"
- **kind:** static
- **source:** code

### `save_note_cole`
- **screen:** Unlock and save notes
- **when:** Save-note banner on the next launch if Season Complete was already stored and Cole was not marked unlocked. Two fresh unlocks are joined with a comma and a space.
- **current:** "Cole Lang unlocked"
- **kind:** static
- **source:** code

### `save_note_carlos`
- **screen:** Unlock and save notes
- **when:** Save-note banner on the next launch if the stored longest make is at least 100 and Carlos was not marked unlocked.
- **current:** "Carlos Hernandez unlocked"
- **kind:** static
- **source:** code

### `save_note_join`
- **screen:** Unlock and save notes
- **when:** Save-note banner when both of those recorded unlocks happen on the same launch.
- **current:** "{first_unlock}, {second_unlock}"
- **kind:** template
- **source:** code

### `save_reset_warn`
- **screen:** Unlock and save notes
- **when:** Save-note banner after one F9, on the title, menu, select, records, or in-game screens.
- **current:** "Press F9 again to reset save."
- **kind:** static
- **source:** code

### `save_reset_done`
- **screen:** Unlock and save notes
- **when:** Save-note banner after a second F9 within two seconds.
- **current:** "Save reset"
- **kind:** static
- **source:** code

### `save_note_locked_hint`
- **screen:** Unlock and save notes
- **when:** Save-note banner if a locked kicker is confirmed. The words are that kicker's unlock hint, already listed on the locked card.
- **current:** "{unlock_hint}"
- **kind:** template
- **source:** code

## Not drawn

These strings were searched for and are not shown to a player. They are not in the counts above.

### `kicker_bruce_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "A farmer who's been booting fence posts loose since he was nine. He can kick it a mile. The hay ball goes where the wind takes it."
- **kind:** static
- **source:** code

### `kicker_bruce_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "The Farm Ball. Wind pushes it 10% more."
- **kind:** static
- **source:** code

### `kicker_walk_on_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "Nobody recruited him. He showed up to tryouts in borrowed cleats and never left."
- **kind:** static
- **source:** code

### `kicker_walk_on_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "No standout strength."
- **kind:** static
- **source:** code

### `kicker_phil_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "He compounds the little things. The shop knows his name, and the gelcap only pays when he actually took it."
- **kind:** static
- **source:** code

### `kicker_phil_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "55 yards with nothing on. Rerolls still cost cash."
- **kind:** static
- **source:** code

### `kicker_gary_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "He treats a good kick like gold. First-try makes make his gear a little luckier."
- **kind:** static
- **source:** code

### `kicker_gary_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "No Farm Strength. A miss still misses."
- **kind:** static
- **source:** code

### `kicker_vex_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "The saucer does not need a yard cap. It clears the posts, then keeps curving left."
- **kind:** static
- **source:** code

### `kicker_vex_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "The Flying Saucer always curves left."
- **kind:** static
- **source:** code

### `kicker_cole_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "The brand wants the middle of the posts, not a bottle on the belt."
- **kind:** static
- **source:** code

### `kicker_cole_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "No vitamins and no B12. The belt stays empty."
- **kind:** static
- **source:** code

### `kicker_willow_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "She takes her time. The first shop of the run always has something that adds yards."
- **kind:** static
- **source:** code

### `kicker_willow_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "50 yards with nothing on. The Chill Ball is slow."
- **kind:** static
- **source:** code

### `kicker_carlos_lore_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws lore.
- **current:** "Smash the power and the accuracy takes care of itself. The ball does not wait around."
- **kind:** static
- **source:** code

### `kicker_carlos_downside_not_drawn`
- **screen:** Not drawn
- **when:** Stored on the kicker. No screen draws the downside.
- **current:** "94 and below is a normal accuracy swing."
- **kind:** static
- **source:** code

### `hud_hint_restart_not_shown`
- **screen:** Not drawn
- **when:** The words exist in the HUD hint code, but that branch only runs in the same phases that clear the hint first. The end screen uses a different line.
- **current:** "R: choose a kicker    Esc: main menu"
- **kind:** static
- **source:** code

### `result_format_detail_not_shown`
- **screen:** Not drawn
- **when:** KickLogic.format_detail is used by tests only. The result banner uses detail_line instead.
- **current:** "P = {power}, e = {error}, angle = {degrees}°"
- **kind:** template
- **source:** code
