# Item, kit, range, and cash audit

Generated: 2026-11-12

**Loadout items:** 26 (12 equipment, 6 perks, 8 curses)
**Vitamins:** 11 (10 belt vitamins and B12 Shot)
**Kickers:** 8
**Kits:** 8
**Mismatches:** 80

This report compares the words on screen with the effects in code. Nothing in the game was changed. Numbers below were taken from `Loadout.apply`, `Loadout.effect_line`, `Kickers.apply_to`, `KickLogic.carry_plan`, `KickLogic.format_number`, and `RunLogic` cash and shop functions.

`format_number` prints a tenth and rounds half away from zero. Anchor and Sticker cards use that printer. The needles use the unrounded factor.

Equipment rank caps are coded: Standard VI, Endless XII. Perk caps: Standard III, Endless VI. Curses stay rank 1. Those caps exist. No rank in that span is missing from `max_rank`.

Style lock, as coded: picking a cleat, helmet, or glove rejects any other id in that slot. A second different perk is allowed. A third perk id is rejected. A second curse is allowed and then `curses_locked` blocks more curses. Ranks still upgrade an owned id. Glass Leg cannot be taken the first time if the attempt cap is already 2 or less. Ice Cage rejects the Iced curse.

Howling Wind multiplies equipment and perk additive numbers by 1.15 after they are summed, and it widens multiplier gaps with `boost_factor`. Curse upside yards and curse Mult are not in that 1.15. Phil's Compounding and Gary's Lucky Ball then pass through `scale_amount` / `scale_gap`. The tables below are with neither of those scales and without Howling Wind. Big Game copies the kicker's base needle, bands, and red-tip values back over the loadout, then still applies vitamins. Range bonuses are not stripped.

The aiming HUD does not show a max-range number. The "{yards} yd" line is the kick's required distance. After the kick, the result detail line prints `max range` from `carry_plan` travel.

## 1. Loadout items

### Cannon Cleats

- **id:** `cannon_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XII
- **card text:** `"+{6 × rank} yd"` at every rank. Rank I is "+6 yd". Rank VI is "+36 yd". Rank XII is "+72 yd".
- **actual effect:** `range_bonus += 6 × rank`. The number is the total for that rank, not an extra 6 on top of the previous rank's bonus. It is included in max range. Big Game keeps it. Howling Wind multiplies it by 1.15 with the other equipment and perk yards.
- **match:** yes, ranks I–XII

### Pinpoint Cleats

- **id:** `pinpoint_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XII
- **card text:** `"PERFECT +{2 × rank}, good +{3 × rank}"`. Rank I is "PERFECT +2, good +3". Rank VI is "PERFECT +12, good +18". Rank XII is "PERFECT +24, good +36".
- **actual effect:** adds those amounts to the kicker's perfect band and good band. Totals, not stacked leftovers. Big Game removes the band adds. Howling Wind multiplies the adds by 1.15.
- **match:** yes, ranks I–XII

### Anchor Cleats

- **id:** `anchor_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XII
- **card text:** `"Needles ×{format_number(0.85 ^ rank)}"`. The printed tenths are 0.9, 0.7, 0.6, 0.5, 0.4, 0.4, 0.3, 0.3, 0.2, 0.2, 0.2, 0.1 for ranks I–XII.
- **actual effect:** both needle speeds are multiplied by the unrounded `0.85 ^ rank`: 0.85, 0.7225, 0.614125, 0.522006, 0.443705, 0.377150, 0.320577, 0.272491, 0.231617, 0.196874, 0.167343, 0.142242. A higher rank replaces the previous factor. It does not stack a second 0.85. Big Game restores the kicker's base needle speeds, so this mul is off during Big Game.
- **match:** mismatch, every rank. The card's tenth is not the factor the needles use. Ranks VI and V both print ×0.4. Ranks VIII and VII both print ×0.3. Ranks IX–XI all print ×0.2.

### Sticker Cleats

- **id:** `sticker_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XII
- **card text:** `"Drift ×{format_number(0.80 ^ rank)}"`. Printed tenths: 0.8, 0.6, 0.5, 0.4, 0.3, 0.3, 0.2, 0.2, 0.1, 0.1, 0.1, 0.1.
- **actual effect:** `drift_factor` is the unrounded `0.80 ^ rank`: 0.8, 0.64, 0.512, 0.4096, 0.32768, 0.262144, 0.209715, 0.167772, 0.134218, 0.107374, 0.085899, 0.068719. Rank I matches. Later ranks do not. Big Game does not clear drift.
- **match:** yes at rank I. Mismatch at ranks II–XII.

### Wind Visor

- **id:** `wind_visor`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XII
- **card text:** Rank I `"Shows wind mph and an arrow"`. Ranks II–V `"Dotted path for {percent}% of this kick"` with 40, 55, 70, 85. Rank VI and Endless VII–XII `"Dotted path for the full flight"`.
- **HUD:** wind name always. With `flag_reader`, `"{mph} mph   cross {cross}   tail {tail}"` and the flag arrow. The dotted path is drawn for `path_percent` of this kick.
- **actual effect:** rank I sets the readout and the arrow, and `path_percent_for_rank` is 0, so no path. Ranks II–V use 40, 55, 70, 85. Rank VI and above use 100. The readout and arrow stay on at every rank, including II–XII. Big Game does not turn this off.
- **match:** rank I yes. Ranks II–XII mismatch: the path percent matches the card, but the mph line and arrow still run and the card no longer says so.

### Ice Cage

- **id:** `ice_cage`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XII
- **card text:** I `"No red-tip penalty. Immune to Iced."` II `"Also accuracy needle ×0.90"` III `"Also PERFECT +1"` IV `"Also good +2"` V `"PERFECT +2 total"` VI and VII–XII `"Good +4 total"`.
- **actual effect:** every rank sets red-tip immunity (`ice_veins`) and blocks the Iced curse and the Iced meter hide. Rank II and up also multiply accuracy needle speed by 0.90 (power needle unchanged). Perfect bonus, one point at each odd rank from III up: +1, +1, +2, +2, +3, +3, +4, +4, +5, +5 at ranks III–XII. Good bonus, +2 at each even rank from IV up: +2, +2, +4, +4, +6, +6, +8, +8, +10 at ranks IV–XII. On the Walk-On's base bands (±1.5 / ±6) that is absolute bands 2.5/6, 2.5/8, 3.5/8, 3.5/10, 4.5/10, 4.5/12, 5.5/12, 5.5/14, 6.5/14, 6.5/16 at ranks III–XII. Big Game clears `ice_veins` and the band adds. The Iced-curse block still keys off the helmet id.
- **match:** rank I yes. Rank II mismatch: the card only names ×0.90. Rank III mismatch: the card only names PERFECT +1. Rank IV mismatch: the card only names good +2. Rank V mismatch: perfect +2 is right, and good +2, ×0.90, and Iced immunity are still on. Rank VI mismatch: good +4 is right, and perfect is +2, not unstated. Ranks VII–XII mismatch: the card stays "Good +4 total" while perfect and good keep rising as above.

### Scout Lid

- **id:** `scout_lid`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XII
- **card text:** Ranks I–III `"+{rank} reroll"`. IV `"+3 rerolls, and one Practice Swing a quarter"`. V `"+4 rerolls, and one Practice Swing a quarter"`. VI and VII–XII `"+5 rerolls, and two Practice Swings a quarter"`.
- **actual effect:** added rerolls are 1, 2, 3, 3, 4, 5, then `rank - 1` (6 through 11 at VII–XII). Practice swings per quarter: 0 through rank III, then 1, 1, 2, 2, 3, 3, 4, 4, 5 at ranks IV–XII. These add to the kicker's own rerolls. Picking the rank adds the gain to rerolls left and practice charges immediately.
- **match:** yes for ranks I–VI. Mismatch for VII–XII: the card stays at +5 rerolls and two practice swings. Code is +6 and 2, +7 and 3, +8 and 3, +9 and 4, +10 and 4, +11 and 5.

### Doink Cap

- **id:** `doink_cap`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XII
- **card text:** Ranks I–V `"{rank} doink-to-good a quarter"`. Rank VI and VII–XII `"5 doink-to-good a quarter, unused carry (max 5)"`.
- **actual effect:** ranks I–V grant that many doink-to-good charges and do not carry. Rank VI grants 5 and carries unused charges, capped at another 5. Ranks VII–XII grant `rank` charges (7 through 12) and carry unused charges capped at that same number, not at 5.
- **match:** yes for ranks I–VI. Mismatch for VII–XII.

### Drive Lid

- **id:** `drive_lid`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XII
- **card text:** `"+{4 × rank} yd"`. Rank I "+4 yd". Rank VI "+24 yd". Rank XII "+48 yd".
- **actual effect:** `range_bonus += 4 × rank`. Total for that rank. Big Game keeps it. Howling Wind multiplies it by 1.15 with other equipment yards. No sprite, so the icon draws "Drive".
- **match:** yes, ranks I–XII

### Iron Grip

- **id:** `iron_grip`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XII
- **card text:** Ranks I–II `"Red-tip noise −{2 × rank}"`. III `"Noise −4 (min ±1), red tip 3 later"`. IV `"Noise −4 (min ±1), red tip 6 later"`. V `"Noise −4 (min ±1), red tip 9 later"`. VI and VII–XII `"Red tip never triggers"`.
- **actual effect:** noise starts at 5. The cut is `2 × min(rank, 2)`, floored at 1, so rank I is ±3 and rank II and up are ±1. Red-tip start begins at 95 and gains +3 at rank III, +3 more at IV, and +3 more at V (98, 101, 104). Rank VI and up set `red_tip_off`, so the red tip does not add noise. Big Game restores the base red-tip start, noise, and turns `red_tip_off` off.
- **match:** yes, ranks I–XII. The rank VI sentence still matches VII–XII because the off switch does not grow.

### Replay Gloves

- **id:** `replay_gloves`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XII
- **card text:** Ranks I–V `"{rank} practice swing a quarter"`. Rank VI and VII–XII `"5 practice swings, unused carry (max 5)"`.
- **actual effect:** ranks I–V add that many practice swings and do not carry. Rank VI adds 5 and carries unused swings, capped at 5. Ranks VII–XII add `rank` swings (7 through 12) and carry unused swings capped at that number, not at 5.
- **match:** yes for ranks I–VI. Mismatch for VII–XII.

### High-Air Gloves

- **id:** `high_air`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XII
- **card text:** `"+{2 × rank} yd, tailwind range ×1.5"`.
- **actual effect:** `range_bonus += 2 × rank`, and positive wind range (tailwind only) is multiplied by 1.5. Headwind is not multiplied. Big Game keeps the yards and the tailwind flag.
- **match:** yes, ranks I–XII

### Weather Wraps

- **id:** `weather_wraps`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XII
- **card text:** I `"Rain, snow, and mud penalties cut in half"`. II `"Rain, snow, and mud penalties ignored"`. III `"Also ignores Monsoon's rain and mud"`. IV `"Penalties ignored, +2 yd unless CLEAR"`. V `"Penalties ignored, +4 yd unless CLEAR"`. VI and VII–XII `"Penalties ignored, +6 yd unless CLEAR"`.
- **actual effect:** rank I halves rain needle speed, snow yards, and mud power span, and does not stop Monsoon. Rank II ignores plain rain, snow, and mud, and Monsoon still applies. Rank III and up ignore Monsoon rain and mud as well. From rank IV, yards are `2 × (rank - 3)` when the weather is not CLEAR: 2, 4, 6, 8, 10, 12, 14, 16, 18 at ranks IV–XII. Howling Wind multiplies those yards by 1.15. CLEAR adds none.
- **match:** yes for ranks I–VI. Mismatch for VII–XII: the card stays at +6 yd. Code is +8 through +18.

### Deep Bench

- **id:** `deep_bench`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** Ranks I–II `"Attempt cap +{rank} and attempts +{rank}"`. Rank III and Endless IV–VI `"Cap stays. +1 attempt now and each quarter if below cap"`.
- **actual effect:** the cap increase is `min(rank, 2)`, then clamped to 5. Taking the rank adds that cap gain to current attempts. Rank III and up also set the spare: +1 attempt immediately if below the cap, and +1 at each quarter refill if below the cap. Ranks IV–VI do not raise the cap or the spare past rank III.
- **match:** yes for ranks I–III. Mismatch for IV–VI: those ranks reuse rank III's effect.

### Hot Streak

- **id:** `hot_streak`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"Streak step +0.5"`. II `"Streak step +0.75"`. III and IV–VI `"Streak step +1.0"`.
- **actual effect:** replaces the base step of 0.25. Rank I is 0.5. Rank II is 0.75. Rank III and up is `1.0 + 0.25 × (rank - 3)`: 1.0, 1.25, 1.5, 1.75 at ranks III–VI. The HUD Mult uses `1 + step × streak`, then Showtime's stored double.
- **match:** yes for ranks I–III. Mismatch for IV–VI: the card stays at +1.0 while the step is 1.25, 1.5, and 1.75.

### Storm Chaser

- **id:** `storm_chaser`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"+0.2 Mult per mph of crosswind"`. II `"+0.4 Mult per mph of crosswind"`. III and IV–VI `"+0.6 Mult per mph of crosswind"`.
- **actual effect:** `0.2 × rank` Mult per mph of crosswind: 0.2, 0.4, 0.6, 0.8, 1.0, 1.2 at ranks I–VI. Howling Wind multiplies that rate by 1.15.
- **match:** yes for ranks I–III. Mismatch for IV–VI.

### Hero Ball

- **id:** `hero_ball`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"+1.0 Mult, both needles ×0.80"`. II `"+1.5 Mult, both needles ×0.80"`. III and IV–VI `"+2.0 Mult, both needles ×0.80"`.
- **actual effect:** Mult add is 1.0, 1.5, then `2.0 + 0.5 × (rank - 3)`: 2.0, 2.5, 3.0, 3.5 at ranks III–VI. Both needles stay at ×0.80 at every rank. Big Game removes the needle slow and keeps the Mult. Howling Wind multiplies the Mult by 1.15 and widens the 0.80 gap.
- **match:** yes for ranks I–III. Mismatch for IV–VI: the Mult keeps rising and the card stays at +2.0.

### Glass Leg

- **id:** `glass_leg`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"+8 yd, attempt cap −1"`. II `"+16 yd total, no extra cap loss"`. III and IV–VI `"+24 yd total, no extra cap loss"`.
- **actual effect:** `range_bonus += 8 × rank` (8, 16, 24, 32, 40, 48). The attempt cap is reduced by 1 once, floored at 1, at every rank. It is not reduced again at rank II or higher. The first take is refused when the cap is already 2 or less.
- **match:** yes for ranks I–III. Mismatch for IV–VI: yards are 32, 40, and 48, not 24.

### Two-Minute Drill

- **id:** `two_minute_drill`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"Boss kicks +0.5 Mult, on top of ×1.5"`. II `"Boss kicks +1.0 Mult, on top of ×1.5"`. III and IV–VI `"Boss kicks +1.5 Mult, on top of ×1.5"`.
- **actual effect:** adds `0.5 × rank` Mult on top of the boss score ×1.5: 0.5, 1.0, 1.5, 2.0, 2.5, 3.0 at ranks I–VI. Howling Wind multiplies this add by 1.15.
- **match:** yes for ranks I–III. Mismatch for IV–VI.

### Iced

- **id:** `iced`
- **slot:** curse
- **rank cap:** 1 in both modes
- **card text:** `"Down: meter hides 0.4s after Space. Up: +0.5 Mult"`
- **HUD:** the curse name, unless Howling Wind replaces the curse list with its own line.
- **actual effect:** +0.5 Mult. While the meter is running, the meter stays visible until 0.4 seconds after it starts, then stays hidden. Ice Cage blocks the hide and blocks taking this curse. The +0.5 Mult is not multiplied by Howling Wind's 1.15.
- **match:** yes

### Shanky Cleats

- **id:** `shanky_cleats`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: accuracy error ×1.5. Up: +0.5 Mult"`
- **actual effect:** `angle_scale` is 1.5, so the hook degrees from accuracy error are ×1.5. +0.5 Mult. The Mult is not multiplied by Howling Wind's 1.15.
- **match:** yes

### Heavy Ball

- **id:** `heavy_ball`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: −4 yd. Up: accuracy error ×0.85"`
- **actual effect:** `carry_plan` subtracts 4 yards after wind and weather range. `angle_scale` is 0.85. The 4 yards are not in `range_bonus`, so they show up in the result line's max range, not as a loadout yard add. Howling Wind does not shrink or grow this 4.
- **match:** yes

### Howling Wind

- **id:** `howling_wind`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: wind ×1.5. Up: equipment and perks ×1.15"`
- **HUD:** `"Howling Wind   wind ×1.5   items ×1.15"` instead of the curse-name list.
- **actual effect:** the wind vector used for drift and wind range is ×1.5, and the shown mph is that speed rounded. Equipment and perk additive yards, perfect adds, good adds, Hero Ball, Storm Chaser, and Two-Minute Drill are ×1.15. Anchor, Sticker, Ice Cage's 0.90, and Hero Ball's 0.80 have their gap from 1.0 widened by 15%. Curse upside yards and curse Mult are not ×1.15. Weather Wraps' bonus yards are ×1.15 because they are applied with the Howling check.
- **match:** yes

### Shaky Arrow

- **id:** `shaky_arrow`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: aim sways ±3°. Up: +6 yd"`
- **actual effect:** during aiming, the aim is `aim_base + sin(time × 1.6) × 3` degrees, clamped to ±12. +6 yards in `range_bonus`. The path preview uses `aim_base` and does not include the sway. The +6 is not multiplied by Howling Wind's 1.15.
- **match:** yes

### Narrow Posts

- **id:** `narrow_posts`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: posts 5.17 yd. Up: +0.5 Mult"`
- **actual effect:** post width is 5.17 yards and the make/miss half-gap is 2.585, the same numbers as The Squeeze. +0.5 Mult. The Mult is not multiplied by Howling Wind's 1.15.
- **match:** yes

### Stone Toe

- **id:** `stone_toe`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: power needle ×1.20. Up: +6 yd"`
- **actual effect:** power needle speed ×1.20. +6 yards in `range_bonus`. Big Game keeps the ×1.20 and resets other loadout needle changes. The +6 is not multiplied by Howling Wind's 1.15.
- **match:** yes

### Tight Window

- **id:** `tight_window`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: PERFECT and good −2. Up: +0.5 Mult"`
- **actual effect:** after other band adds, both bands lose 2, floored at 1, and perfect is not allowed to exceed good. +0.5 Mult. Big Game applies the −2 again on the kicker's base bands. The Mult is not multiplied by Howling Wind's 1.15.
- **match:** yes

## 2. Vitamins and shop services

Prices below are the shelf prices. Phil's House Account charges 0 for every id, including B12. Selling pays `floor(charged price / 2)`, so Phil's sell pays 0. A use is removed from the belt immediately. Ball vitamins are cleared when the kick resolves, including a miss, so the retry does not still have them. Phil's 15% and Gary's Lucky Ball scale the vitamin numbers through the same `item_effect_scale` as loadout numbers.

### Protein Shake

- **id:** `protein_shake`
- **price:** 4
- **shop text:** `"+6 yd this kick"`
- **actual effect:** +6 yards on that attempt, scaled by Phil or Gary. Cleared when the kick resolves. Willow's first shop opening forces this bottle into the first shelf slot if it was not already drawn.
- **match:** yes

### Magnesium

- **id:** `magnesium`
- **price:** 4
- **shop text:** `"Needles ×0.7 this kick"`
- **actual effect:** both needle speeds ×0.7 for that attempt. One bottle is ×0.7. Big Game does not remove it, because vitamins are applied after Big Game restores base needle speeds.
- **match:** yes

### Omega-3

- **id:** `omega_3`
- **price:** 5
- **shop text:** `"Good band wipes the angle error"`
- **actual effect:** if the accuracy press is inside the good band, the angle error is set to 0. The perfect score bonus of +5 is also suppressed for that make. Cash still uses the original perfect flag. The card does not mention the score bonus.
- **match:** mismatch

### Electrolyte Tabs

- **id:** `electrolyte_tabs`
- **price:** 6
- **shop text:** `"A miss keeps the attempt"`
- **actual effect:** a miss does not subtract an attempt and does not end the run for 0 attempts. The bottle is still cleared, so the retry does not keep the protection.
- **match:** yes

### Vitamin D

- **id:** `vitamin_d`
- **price:** 5
- **shop text:** `"Ignore rain, snow, and mud"`
- **actual effect:** for that attempt, rain, snow, and mud flags are off, including Monsoon's rain and mud. It does not add the Weather Wraps yards.
- **match:** yes

### Pre-Workout

- **id:** `pre_workout`
- **price:** 4
- **shop text:** `"+0.5 Mult if this kick is made"`
- **actual effect:** on a make, +0.5 Mult, scaled by Phil or Gary. A miss pays no Mult and still consumes it.
- **match:** yes

### Zinc

- **id:** `zinc`
- **price:** 5
- **shop text:** `"Reroll this kick's wind and weather"`
- **actual effect:** instant. Rerolls this kick's wind and weather once. A second Zinc on the same kick shows `"Already rerolled"` and is not consumed. It does not sit in the active-vitamin list, so Phil's Gelcap does not see it.
- **match:** yes

### Lutein

- **id:** `lutein`
- **price:** 5
- **shop text:** `"Wind numbers and a full dotted path"`
- **actual effect:** for that attempt, the mph readout and a 100% dotted path turn on. Cleared when the kick resolves.
- **match:** yes

### Pickle Juice

- **id:** `pickle_juice`
- **price:** 5
- **shop text:** `"Sideways wind drift ×0.5"`
- **actual effect:** drift factor ×0.5 for that attempt. Phil or Gary scale the gap from 1.0.
- **match:** yes

### Tart Cherry

- **id:** `tart_cherry`
- **price:** 6
- **shop text:** `"Remove one curse"`
- **actual effect:** instant. With no curse, the note is `"No curse to remove"`. With curses, the overlay asks which one. Esc cancels and the bottle stays. Removing one spends the bottle.
- **match:** yes

### B12 Shot

- **id:** `b12_shot`
- **price:** 7
- **shop text:** `"B12 Shot"` and `"+1 attempt"`. Also `"SOLD"` after a buy and `"At cap"` when attempts are already at the cap.
- **actual effect:** instant, not a belt item, once per shop visit. Adds 1 attempt, not above the cap. If already at the cap, the buy does nothing. Short cash flashes the price red and adds no words.
- **match:** yes

### Shelf reroll

- **shop text:** `"Reroll ({key}): ${price}"`. The price number is the live cost.
- **actual effect:** starts at 2 and increases by 1 after each paid reroll. It spends cash, not a loadout reroll. Too little cash flashes red and adds no words. Phil does not make this free.
- **match:** yes

### Sell and a full belt

- **shop text:** the footer names sell and leave. A refused buy can show `"Belt full: sell first"`.
- **actual effect:** the belt has 2 slots. Sell pays half the charged price, rounded down, only while the shop is open. Leave closes the shop. A buy into a full belt is refused with that sentence.
- **match:** yes

No shop string states the make / perfect / middle / boss cash table. Those rules are only in code. See section 5.

## 3. Kicker kits and balls

Base max range here is `carry_plan` at the stated power, 0 wind, no items, no weather penalty. For a normal kicker that result does not depend on the kick's required distance. For Vex it does. The 35-yard column uses kick distance 35. Accuracy is the rating in the kicker table. Perfect and good bands start at `1.5 × accuracy / 100` and `6 × accuracy / 100`.

| Kicker | Accuracy | Bands | 100% power, no items |
| --- | --- | --- | --- |
| Big Bruce | 90 | ±1.35 / ±5.40 | 65 yd |
| The Walk-On | 100 | ±1.50 / ±6.00 | 60 yd |
| Phil The Pharmacist | 112 | ±1.68 / ±6.72 | 55 yd |
| Gary the Goat | 98 | ±1.47 / ±5.88 | 65 yd |
| Vex | 94 | ±1.41 / ±5.64 | kick distance + 20 yd |
| Cole Lang | 120 | ±1.80 / ±7.20 | 70 yd |
| Willow Reed | 88 | ±1.32 / ±5.28 | 50 yd |
| Carlos Hernandez | 96 | ±1.44 / ±5.76 | 66 yd |

### Big Bruce

- **Select range:** `"65 yd"`
- **Kit text:** `"Farm Strength. A press under 80% still kicks at 80%."` HUD kit line `"Farm Strength"`.
- **actual effect:** `power_floor` is 80. A locked power under 80 is treated as 80 before range. A 100% lock stays 100. Full power is `16 + 0.49 × 100` = 65 yards before wind and items.
- **match:** yes
- **Ball:** `"The Farm Ball"`. `"A light hay ball. Wind moves it 10% more than a normal ball. A doink stays a doink."`
- **actual effect:** `ball_type` `farm_ball` multiplies sideways drift by 1.10. Nothing turns a doink into a make.
- **match:** yes

### The Walk-On

- **Select range:** `"60 yd"`
- **Kit text:** `"Earns His Spot. 2 rerolls a run."` HUD kit line `"Earns His Spot"`.
- **actual effect:** `rerolls_per_run` is set to 2. Other kickers keep the default 1, before Scout Lid. Full power is `16 + 0.44 × 100` = 60 yards.
- **match:** yes
- **Ball:** `"Team-Issue"`. `"A normal ball. No special trick."`
- **actual effect:** `ball_type` `standard`. No extra drift, range, or needle change. `ball_speed_mult` stays 1.
- **match:** yes

### Phil The Pharmacist

- **Select range:** `"55 yd"`
- **Kit text:** `"House Account. Compounding. Shop items are free and 15% stronger."` Downside on the card: `"55 yards with nothing on. Rerolls still cost cash."` HUD kit line `"House Account"`.
- **actual effect:** full power is `16 + 0.39 × 100` = 55 yards. `house_account` makes every `item_price` return 0, including B12. The shop shelf reroll still charges its cash cost. `compounding` sets item scale to 1.15. That scale hits equipment yards and bands, perk numbers, curse upside yards and curse Mult, and vitamin numbers. It is not limited to shop goods. Factors move by widening the gap from 1.0. Yard amounts then pass through `round_tenth`.
- **match:** mismatch. The 15% is not only shop items.
- **Ball:** `"The Gelcap"`. `"A vitamin used on this attempt adds +0.5 Mult on a make."`
- **actual effect:** if at least one ball vitamin is active when a make is scored, +0.5 Mult once. It is not +0.5 per bottle. Zinc and Tart Cherry do not count, because they never enter the active list. The 0.5 is not scaled by Compounding.
- **match:** yes

### Gary the Goat

- **Select range:** `"65 yd"`
- **Kit text:** `"Good As Gold. The good band counts as PERFECT."` HUD kit line `"Good As Gold"`.
- **actual effect:** a lock inside the good band sets accuracy error to 0 and `perfect` true, including the perfect cash dollar. Full power is 65 yards, same range slope as Bruce, without the power floor.
- **match:** yes
- **Ball:** `"Lucky Ball"`. `"Each first-try make boosts item numbers by 3% for the rest of the run."`
- **actual effect:** each make on the first ball of that kick adds one stack. Item scale is multiplied by `1 + 0.03 × stacks` for the rest of the run. A miss does not add a stack. The same amounts Compounding scales are the ones this hits.
- **match:** yes

### Vex

- **Select range:** `"Infinite Range & Beyond"`
- **Kit text:** `"Infinite Range & Beyond. 88% power clears by 5 yards."` HUD kit line `"Infinite Range & Beyond"`.
- **actual effect:** `range_base` and `range_per_power` are 0. Travel is `kick distance + 5 + (power - 88) × 1.25`, plus items and wind range. At 88% the added clearance is 5 yards before wind and penalties. At 100% it is 20 yards. If power is at least 88 and wind or a penalty would leave the ball short of the posts, travel is raised back to the kick distance. It is not raised back up to a 5-yard clearance. There is no separate yard cap.
- **match:** mismatch. "Clears by 5 yards" is the no-wind number. A headwind, snow, or Heavy Ball can shrink that clearance, down to just reaching the posts.
- **Ball:** `"The Flying Saucer"`. `"Curves left like 8 mph of west wind, on top of the real wind."`
- **actual effect:** 8 mph is subtracted from the crosswind component before drift and wind range. That is on top of the real wind, and Howling Wind then scales the combined vector.
- **match:** yes

### Cole Lang

- **Select range:** `"70 yd"`
- **Kit text:** `"Brand Deal. Loadout offers stay. The Vitamin Shop does not."` HUD kit line `"Brand Deal"`.
- **actual effect:** after a make on kick 5, 10, or 15, the loadout offer still runs and `open_shop` is skipped. Full power is `16 + 0.54 × 100` = 70 yards. `ball_speed_mult` stays 1.
- **match:** yes
- **Ball:** `"Showtime"`. `"A down-the-middle make doubles stored Mult, and that kick scores with the doubled Mult."`
- **actual effect:** on a down-the-middle make, the Mult used for that kick's score is doubled, and the stored Showtime factor is then doubled for later kicks. The stored factor also multiplies the normal streak Mult. A miss sets the stored factor back to 1.
- **match:** yes

### Willow Reed

- **Select range:** `"50 yd"`
- **Kit text:** `"Synchronicity. The first shop opening includes a range vitamin."` HUD kit line `"Synchronicity"`.
- **actual effect:** the first time the shop opens, if Protein Shake is not already one of the three bottles, shelf slot 1 is replaced with Protein Shake. Later openings and paid rerolls are not forced. It does not add a range loadout card. Full power is `16 + 0.34 × 100` = 50 yards before that vitamin is used. Using Protein Shake adds 6 yards on that attempt, so the kick can travel 56 yards with no other range items.
- **match:** yes
- **Ball:** `"The Chill Ball"`. `"Both needles run at half speed. Items and weather still stack on top."`
- **actual effect:** `ball_speed_mult` is 0.50, so both the power sweep and the accuracy sweep take twice as long before items and weather. Magnesium, Anchor, rain, and the other speed multipliers still stack on that half speed.
- **match:** yes

### Carlos Hernandez

- **Select range:** `"66 yd"`
- **Kit text:** `"Numero Dos. A 95–100 lock is a true PERFECT."` Downside on the card: `"94 and below is a normal accuracy swing."` HUD kit line `"Numero Dos"`.
- **actual effect:** if the locked power is from 95 through 100, accuracy error is set to 0 and the kick is perfect, including through red-tip noise. A power of 94 or below uses the normal accuracy swing. An auto-shank never reaches this check. Full power is `16 + 0.50 × 100` = 66 yards.
- **match:** yes
- **Ball:** `"The Not So Secret Weapon"`. `"Both needles run 15% faster. Items and weather still stack on top."`
- **actual effect:** `ball_speed_mult` is 1.15. Items and weather still multiply needle speed on top.
- **match:** yes

## 4. Max-range formula

The live kick calls `power_for_range` first. If the kicker's power floor is above 0 and the locked power is below it, the power used for range is the floor. Bruce's floor is 80. Everyone else has floor 0. `carry_plan` then runs in this order:

1. Build the wind vector. Crosswind is `speed × sin(direction)`. Head or tail is `speed × cos(direction)`. Vex subtracts 8 mph from the crosswind. Howling Wind multiplies the combined speed by 1.5.
2. Wind range is `head_or_tail mph × 0.4`. High-Air Gloves multiply that change by 1.5 only when it is positive.
3. If the kicker has clearance (Vex): `travel = kick distance + 5 + (power - 88) × 1.25 + range_bonus + wind range`.
4. Otherwise: `travel = 16 + range_per_power × power + range_bonus + wind range`.
5. If snow is punishing range, subtract 4 yards, or 2 if Weather Wraps rank I has halved it.
6. If the weather is THIN AIR, add 4 yards. This is separate from High-Air's tailwind multiplier.
7. If Heavy Ball is active, subtract 4 yards.
8. Floor at 0.
9. If Vex's power is at least 88 and travel is still short of the kick distance, set travel to the kick distance.

`range_bonus` before that call is the sum of Cannon, Drive Lid, High-Air, and Glass Leg yards, times 1.15 if Howling Wind is active, plus Shaky Arrow and Stone Toe at +6 each with no Howling 1.15, then Phil or Gary's scale. Weather Wraps yards are added after that, only when weather is not CLEAR, and those yards are ×1.15 under Howling Wind. Protein Shake is added when vitamins are applied.

The result detail line's "max range" is this travel. The aiming HUD does not show it.

Worked examples use 0 wind, no weather penalty, no Howling Wind, and no Phil or Gary scale. Kick distance is 35 yards except where noted. They call `carry_plan` at the stated power.

- Big Bruce, no items, 100% power: **65 yd** (`16 + 0.49 × 100`).
- Big Bruce, Cannon Cleats rank VI, 100% power: **101 yd** (65 + 36).
- Big Bruce, Cannon Cleats rank XII, 100% power: **137 yd** (65 + 72).
- Big Bruce, Drive Lid rank VI, 100% power: **89 yd** (65 + 24).
- Big Bruce, Drive Lid rank XII, 100% power: **113 yd** (65 + 48).
- Willow, no items, 100% power: **50 yd** (`16 + 0.34 × 100`).
- Willow with the Synchronicity Protein Shake used, and no other range item: **56 yd**. The shop gift does not add range until that bottle is used.
- Vex, no items, 88% power, kick distance 35: **40 yd** (35 + 5).
- Vex, no items, 100% power, kick distance 35: **55 yd** (35 + 20).
- Vex, Cannon Cleats rank I, 88% power, kick distance 35: **46 yd**.
- Vex, Cannon Cleats rank I, 100% power, kick distance 35: **61 yd**.
- The same Vex 100% kick with no items at kick distance 50 travels **70 yd**. A normal kicker's 100% travel does not change with the required distance. Bruce is still 65 at a 50-yard kick.

## 5. Cash and Vitamin Shop rules

Cash starts at 0 on every new run. It is not written into the save. A finished run does not carry it forward.

`cash_payout` pays 0 on a miss. A make pays 3, plus 1 if the kick was perfect, plus 1 if it was down the middle, plus 2 if it was a boss kick. Those can stack. Omega-3 can suppress the +5 score bonus and still leave the perfect dollar on the original perfect flag. Gary's Good As Gold makes a good-band lock count as perfect for that dollar. The HUD shows `"${cash}"` and, when the payout is above 0, `"+${amount}"`. No sentence on the shop or the HUD states the 3 / 1 / 1 / 2 table.

The shop opens only after a make on kick 5, 10, or 15. That is the same in Standard and Endless. Later Endless kicks do not open it. Cole's Brand Deal skips it. The loadout offer still happens. The first opening of a run is the one Willow can force a Protein Shake into.

Shelf reroll starts at $2 and rises by $1 after each purchase. It is cash. Phil does not zero it. The on-screen `"Reroll ({key}): ${price}"` matches that live price.

The belt has two slots. Sell is allowed only in the shop and pays half the price that was charged, rounded down. Phil's charged price is 0, so the refund is 0. A buy with a full belt shows `"Belt full: sell first"` and does not take the bottle. A buy without enough cash turns the price red and adds no words. Leave closes the shop. B12 is separate from the belt, costs 7 unless Phil is playing, adds one attempt up to the cap, and can be bought once per visit.

There is no shop sentence that says Phil's bottles are free. The price line prints `$0` because `item_price` returns 0. That display matches the code. Cole has no shop to show an exception on. Willow's rule is not written in the shop. It is only the character-select line, which matches the force on the first opening.

## 6. Mismatch index

- `anchor_cleats` rank I: card says Needles ×0.9. Code multiplies both needles by 0.85.
- `anchor_cleats` rank II: card says ×0.7. Code uses 0.7225.
- `anchor_cleats` rank III: card says ×0.6. Code uses 0.614125.
- `anchor_cleats` rank IV: card says ×0.5. Code uses 0.522006.
- `anchor_cleats` rank V: card says ×0.4. Code uses 0.443705.
- `anchor_cleats` rank VI: card says ×0.4, the same tenth as rank V. Code uses 0.377150.
- `anchor_cleats` rank VII: card says ×0.3. Code uses 0.320577.
- `anchor_cleats` rank VIII: card says ×0.3, the same tenth as rank VII. Code uses 0.272491.
- `anchor_cleats` rank IX: card says ×0.2. Code uses 0.231617.
- `anchor_cleats` rank X: card says ×0.2. Code uses 0.196874.
- `anchor_cleats` rank XI: card says ×0.2. Code uses 0.167343.
- `anchor_cleats` rank XII: card says ×0.1. Code uses 0.142242.
- `sticker_cleats` rank II: card says Drift ×0.6. Code uses 0.64.
- `sticker_cleats` rank III: card says ×0.5. Code uses 0.512.
- `sticker_cleats` rank IV: card says ×0.4. Code uses 0.4096.
- `sticker_cleats` rank V: card says ×0.3. Code uses 0.32768.
- `sticker_cleats` rank VI: card says ×0.3, the same tenth as rank V. Code uses 0.262144.
- `sticker_cleats` rank VII: card says ×0.2. Code uses 0.209715.
- `sticker_cleats` rank VIII: card says ×0.2. Code uses 0.167772.
- `sticker_cleats` rank IX: card says ×0.1. Code uses 0.134218.
- `sticker_cleats` rank X: card says ×0.1. Code uses 0.107374.
- `sticker_cleats` rank XI: card says ×0.1. Code uses 0.085899.
- `sticker_cleats` rank XII: card says ×0.1, the same tenth as ranks IX–XI. Code uses 0.068719.
- `wind_visor` ranks II–XII: the path percent matches the card. The mph readout and arrow still run, and the card no longer says so.
- `ice_cage` rank II: the card only says the accuracy needle ×0.90. Red-tip immunity and Iced immunity still run.
- `ice_cage` rank III: the card only says PERFECT +1. The ×0.90 and the immunities still run.
- `ice_cage` rank IV: the card only says good +2. Perfect +1, ×0.90, and the immunities still run.
- `ice_cage` rank V: the card says PERFECT +2 total. Good is also +2, the accuracy needle is still ×0.90, and the immunities still run.
- `ice_cage` rank VI: the card says Good +4 total. Perfect bonus is +2, the accuracy needle is still ×0.90, and the immunities still run.
- `ice_cage` rank VII: the card still says Good +4 total. Code is perfect +3 and good +4, plus ×0.90 and the immunities.
- `ice_cage` rank VIII: the card still says Good +4 total. Code is perfect +3 and good +6, plus ×0.90 and the immunities.
- `ice_cage` rank IX: the card still says Good +4 total. Code is perfect +4 and good +6, plus ×0.90 and the immunities.
- `ice_cage` rank X: the card still says Good +4 total. Code is perfect +4 and good +8, plus ×0.90 and the immunities.
- `ice_cage` rank XI: the card still says Good +4 total. Code is perfect +5 and good +8, plus ×0.90 and the immunities.
- `ice_cage` rank XII: the card still says Good +4 total. Code is perfect +5 and good +10, plus ×0.90 and the immunities.
- `scout_lid` rank VII: the card says +5 rerolls and two practice swings. Code adds 6 rerolls and 2 practice swings.
- `scout_lid` rank VIII: the card says +5 and two. Code adds 7 rerolls and 3 practice swings.
- `scout_lid` rank IX: the card says +5 and two. Code adds 8 rerolls and 3 practice swings.
- `scout_lid` rank X: the card says +5 and two. Code adds 9 rerolls and 4 practice swings.
- `scout_lid` rank XI: the card says +5 and two. Code adds 10 rerolls and 4 practice swings.
- `scout_lid` rank XII: the card says +5 and two. Code adds 11 rerolls and 5 practice swings.
- `doink_cap` rank VII: the card says 5 charges and carry max 5. Code grants 7 and carries up to 7.
- `doink_cap` rank VIII: the card says 5 and max 5. Code grants 8 and carries up to 8.
- `doink_cap` rank IX: the card says 5 and max 5. Code grants 9 and carries up to 9.
- `doink_cap` rank X: the card says 5 and max 5. Code grants 10 and carries up to 10.
- `doink_cap` rank XI: the card says 5 and max 5. Code grants 11 and carries up to 11.
- `doink_cap` rank XII: the card says 5 and max 5. Code grants 12 and carries up to 12.
- `replay_gloves` rank VII: the card says 5 swings and carry max 5. Code grants 7 and carries up to 7.
- `replay_gloves` rank VIII: the card says 5 and max 5. Code grants 8 and carries up to 8.
- `replay_gloves` rank IX: the card says 5 and max 5. Code grants 9 and carries up to 9.
- `replay_gloves` rank X: the card says 5 and max 5. Code grants 10 and carries up to 10.
- `replay_gloves` rank XI: the card says 5 and max 5. Code grants 11 and carries up to 11.
- `replay_gloves` rank XII: the card says 5 and max 5. Code grants 12 and carries up to 12.
- `weather_wraps` rank VII: the card says +6 yd unless CLEAR. Code adds 8.
- `weather_wraps` rank VIII: the card says +6 yd. Code adds 10.
- `weather_wraps` rank IX: the card says +6 yd. Code adds 12.
- `weather_wraps` rank X: the card says +6 yd. Code adds 14.
- `weather_wraps` rank XI: the card says +6 yd. Code adds 16.
- `weather_wraps` rank XII: the card says +6 yd. Code adds 18.
- `deep_bench` rank IV: reuses rank III. Cap stays at +2 and the spare attempt does not grow.
- `deep_bench` rank V: reuses rank III. Same cap and spare.
- `deep_bench` rank VI: reuses rank III. Same cap and spare.
- `hot_streak` rank IV: the card says streak step +1.0. Code sets the step to 1.25.
- `hot_streak` rank V: the card says +1.0. Code sets the step to 1.5.
- `hot_streak` rank VI: the card says +1.0. Code sets the step to 1.75.
- `storm_chaser` rank IV: the card says +0.6 per mph. Code adds 0.8 per mph.
- `storm_chaser` rank V: the card says +0.6 per mph. Code adds 1.0 per mph.
- `storm_chaser` rank VI: the card says +0.6 per mph. Code adds 1.2 per mph.
- `hero_ball` rank IV: the card says +2.0 Mult. Code adds 2.5. Needles stay ×0.80.
- `hero_ball` rank V: the card says +2.0 Mult. Code adds 3.0.
- `hero_ball` rank VI: the card says +2.0 Mult. Code adds 3.5.
- `glass_leg` rank IV: the card says +24 yd total. Code adds 32. The cap loss stays at 1.
- `glass_leg` rank V: the card says +24 yd total. Code adds 40.
- `glass_leg` rank VI: the card says +24 yd total. Code adds 48.
- `two_minute_drill` rank IV: the card says +1.5 Mult. Code adds 2.0 on top of the boss ×1.5.
- `two_minute_drill` rank V: the card says +1.5 Mult. Code adds 2.5.
- `two_minute_drill` rank VI: the card says +1.5 Mult. Code adds 3.0.
- `omega_3`: the card says the good band wipes the angle error. The code also turns off the +5 perfect score bonus. Cash can still pay the perfect dollar.
- `phil` Compounding: the card says shop items are 15% stronger. The 15% also scales equipment, perks, curse upside numbers, and vitamin numbers.
- `vex` kit: the card says 88% power clears by 5 yards. That is the no-wind clearance. Headwind, snow, or Heavy Ball can shrink it, and the code only guarantees the ball reaches the posts.
