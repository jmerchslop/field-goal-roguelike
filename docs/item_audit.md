# Item, kit, range, and cash audit

Generated: 2026-11-14
BAL1: needle slow floor 0.35, gentler Anchor / Patient / Sticker / Shelter tables, and multiplier cards use the printed hundredths.
BAL2: Endless ranks XIII–XXIV do something for every equipment style except Wind Visor and Iron Grip. Range late tables are shorter. Curse upsides are higher, and Howling's item boost is ×1.10.

**Loadout items:** 32 (18 equipment, 6 perks, 8 curses)
**Vitamins:** 11 (10 belt vitamins and B12 Shot)
**Kickers:** 8
**Kits:** 8
**Mismatches:** 1 (Vex's clearance line). BAL1 closed the ten rounding groups on Anchor, Patient, Sticker, Shelter, and True Lid.

Numbers below were taken from `Loadout.effect_line`, `Loadout.apply` / `_apply_piece`, `Loadout.cannon_yards`, `Loadout.drive_yards`, `Loadout.high_air_yards`, `Loadout.effect_rank`, `Kickers.apply_to`, `KickLogic.carry_plan`, and `RunLogic.prepare_kick_stats`. A headless run on 2026-11-14 confirmed the range totals and the needle speeds.

### What changed since the 2026-11-12 audit

- Five equipment styles are in the game: True Lid, Shelter Lid, Guide Gloves, Patient Gloves, Hush Gloves. Drive Lid was already in the 2026-11-12 file.
- Equipment ranks run I–XXIV in Endless and I–VI in Standard. Perks stay I–III Standard and I–VI Endless. Curses stay rank 1.
- BAL2: Cannon, Drive Lid, and High-Air use a shorter XIII–XXIV yard table. Count items keep growing at half their old step. Anchor, Sticker, True Lid, Shelter, Guide, Patient, and Hush keep the XII multiplier and add +1 yd per rank past XII. Wind Visor and Iron Grip still stop at VI.
- The wording pass updated perk cards for ranks IV–VI, the Wind Visor mph line, the Ice Cage cumulative line, and the Scout / Doink / Replay / Weather Wraps lines so they follow `effect_rank`. Those old mismatches are gone.
- BAL1 replaces the Anchor and Patient `0.85^rank` curve, and the Sticker and Shelter `0.80^rank` curve, with the rank I–XII tables below. XIII–XXIV still copy XII. True Lid's hook now uses the same hundredths the card prints. Item, perk, and vitamin slows are multiplied, floored at 0.35, and only then multiplied by Stone Toe, UNDER THE LIGHTS, rain, and ball speed.
- The Bonus Ring can put a second, different style in a filled equipment type. At most two styles per type. Each ranks on its own. Normal offers and the shop do not open that second slot.
- UNDER THE LIGHTS is a boss. Standard kick 10 is a 50/50 roll with The Squeeze. Endless draws it with the other four bosses. Both needles are ×1.35 on top of the kicker and the items. Posts stay 6.17 yards wide.
- Endless opens the Vitamin Shop on every kick number divisible by 5, not only 5, 10, and 15. Standard is still only 5, 10, and 15.
- Willow's Synchronicity now puts a range loadout card on the first generated offer (Cannon, Drive Lid, High-Air, or Glass Leg at rank I). It does not force a Protein Shake onto the shop.

`format_number` still prints a tenth and rounds half away from zero. The multiplier cards do not use it. They use `_two_decimals`.

Style lock, as coded: a type holds one style until a Bonus Ring card puts a different style in the second slot. A third style of that type is rejected. A second different perk is allowed. A third perk id is rejected. A second curse is allowed and then `curses_locked` blocks more curses. Glass Leg cannot be taken the first time if the attempt cap is already 2 or less. Ice Cage, in either helmet slot, rejects the Iced curse.

Howling Wind multiplies the summed equipment and perk yard, band, hero, storm, and drill numbers by 1.10, and it widens each multiplier gap with `boost_factor` before the pieces multiply together. Both pieces of a doubled type go through that same pass. Curse upside yards and curse Mult are not in the equipment 1.10. Phil's Compounding (item scale 1.15) and Gary's Lucky Ball then pass through `scale_amount` / `scale_gap`, again on both pieces. The tables below are with neither of those scales and without Howling Wind, unless a row says otherwise.

Big Game copies the kicker's base needle speeds, bands, and red-tip values back over the loadout, then still applies vitamins. Range bonuses from gear are not stripped. UNDER THE LIGHTS does not do that. It only multiplies needle speed.

The aiming HUD does not show a max-range number. The "{yards} yd" line is the kick's required distance. After the kick, the result detail line prints `max range` from `carry_plan` travel.

## 1. Loadout items

Second-slot rule, from `_apply_piece`: each owned style is applied in full. Additions add. Multipliers multiply. Flags stay on if either piece sets them. Nothing in one equipment type writes the same stat twice, because each type has only one style that touches a given stat. Cannon is the only cleat that adds yards. Drive Lid is the only helmet that adds yards. High-Air is the only glove that adds yards. So no doubled type has two range bonuses. Cannon plus Drive Lid (different types) do add.

Howling and Phil apply to both pieces. The additives are summed first, then Howling's 1.15 and Phil's `scale_amount` hit the sum. Each multiplier is widened on its own, then the factors multiply.

Soft cap: Wind Visor and Iron Grip still stop growing at VI. The other equipment styles change at every rank from XIII through XXIV. Count items use a half step. The shield styles keep the XII multiplier and add flat yards.

### Cannon Cleats

- **id:** `cannon_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** none. XIII–XXIV use `_CANNON_LATE`, not `6 × rank`.
- **card text:** `"+{cannon_yards} yd"` at every rank. The function is the effect.
- **actual effect:** `range_bonus += cannon_yards(rank)`. Total for that rank. Big Game keeps it. Howling multiplies it by 1.15 with the other equipment and perk yards. A second style in another type that also adds yards (Drive Lid or High-Air) adds on top.
- **match:** yes, ranks I–XXIV

| Rank | Yards |
| --- | --- |
| I–XII | 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72 |
| XIII–XXIV | 90, 111, 134, 159, 187, 216, 248, 282, 318, 357, 398, 441 |

### Pinpoint Cleats

- **id:** `pinpoint_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. `effect_rank` stays 12. Card and code both stay PERFECT +24, good +36.
- **card text:** `"PERFECT +{2 × effect_rank}, good +{3 × effect_rank}"`.
- **actual effect:** those amounts are added to the perfect band and the good band. Totals, not leftovers. Big Game removes the band adds. Howling multiplies the adds by 1.15. No other cleat adds bands, so a second cleat does not stack this.
- **match:** yes, ranks I–XXIV

Rank I is +2 / +3. Rank VI is +12 / +18. Rank XII is +24 / +36. Each rank past XII adds +1 PERFECT and +1.5 good. XXIV is +36 / +54.

### Anchor Cleats

- **id:** `anchor_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The factor stays the rank XII table value, 0.40.
- **card text:** `"Needles ×{anchor_factor}"`. The card and the needles use the same table.
- **actual effect:** both needle speeds are multiplied by `anchor_factor(rank)`. A higher rank replaces the previous factor. Big Game restores the kicker's base needle speeds, so this mul is off during Big Game. Patient Gloves multiply only the power needle, after this, if both are owned. Hero Ball's ×0.80 and Magnesium also multiply into the slow product. That product is floored at 0.35 before Stone Toe and UNDER THE LIGHTS.
- **match:** yes, ranks I–XXIV. Card and code are the same hundredths.

| Rank | Card and factor |
| --- | --- |
| I–XII | 0.85, 0.78, 0.72, 0.67, 0.62, 0.58, 0.54, 0.51, 0.48, 0.45, 0.42, 0.40 |
| XIII–XXIV | multiplier stays 0.40. Each rank adds +1 yd, so XXIV is ×0.40 and +12 yd. |

### Sticker Cleats

- **id:** `sticker_cleats`
- **slot:** cleats
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The factor stays the rank XII table value, 0.28.
- **card text:** `"Drift ×{sticker_factor}"`. The card and the drift code use the same table. Sticker does not change needle speed.
- **actual effect:** `drift_factor` is `sticker_factor(rank)`. Big Game does not clear drift. No other cleat writes `drift_factor`.
- **match:** yes, ranks I–XXIV.

| Rank | Card and factor |
| --- | --- |
| I–XII | 0.90, 0.81, 0.73, 0.66, 0.59, 0.53, 0.48, 0.43, 0.39, 0.35, 0.31, 0.28 |
| XIII–XXIV | multiplier stays 0.28. Each rank adds +1 yd, so XXIV is ×0.28 and +12 yd. |

### Wind Visor

- **id:** `wind_visor`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** the path percent stops growing at VI (`min(rank, 6)` inside `path_percent_for_rank`). XIII–XXIV match XII, which already matches VI.
- **card text:** Rank I `"Shows wind mph and an arrow"`. Ranks II–V `"Wind mph and arrow. Dotted path for {40, 55, 70, 85}% of this kick"`. Rank VI and above `"Wind mph and arrow. Dotted path for the full flight, ending at the posts"`.
- **actual effect:** rank I sets the readout and the arrow, and the path percent is 0. Ranks II–V use 40, 55, 70, 85. Rank VI and above use 100. Big Game does not turn this off. A second helmet does not clear the path. Only Wind Visor writes it.
- **match:** yes, ranks I–XXIV

### Ice Cage

- **id:** `ice_cage`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. `effect_rank` stays 12, so perfect stays +5 and good stays +10.
- **card text:** `_ice_cage_line(effect_rank)`. Rank I is immunity only. Rank II adds accuracy ×0.90. Later ranks append the running perfect and good totals.
- **actual effect:** every rank sets `ice_veins` and blocks the Iced curse, in either helmet slot. Rank II and up multiply accuracy speed by 0.90. Perfect +1 at each odd rank from III. Good +2 at each even rank from IV. At XII that is perfect +5 and good +10. Big Game clears `ice_veins` and the band adds. The Iced-curse block still keys off either helmet id.
- **match:** yes, ranks I–XXIV

Rank VI card, confirmed live: `"No red-tip penalty. Immune to Iced. Accuracy needle ×0.90. PERFECT +2, good +4"`. Rank XII and XIII–XXIV: perfect +5, good +10, still ×0.90.

### Scout Lid

- **id:** `scout_lid`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. Rerolls stay at 11 and practice stays at 5 per quarter.
- **card text:** I–III `"+{rank} reroll"`. IV `"+3 rerolls, and one Practice Swing a quarter"`. V `"+4 rerolls, and one Practice Swing a quarter"`. VI `"+5 rerolls, and two Practice Swings a quarter"`. Above VI, `"+{rank-1} rerolls, and {practice} Practice Swings a quarter"` using `effect_rank`.
- **actual effect:** `_scout_rerolls` and `_scout_practice` are what the card prints. Practice from Replay Gloves, a different slot, adds on top.
- **match:** yes, ranks I–XXIV

Rank XII and XIII–XXIV: +11 rerolls and five practice swings a quarter.

### Doink Cap

- **id:** `doink_cap`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. Charges stay at 12, carry max stays at 12.
- **card text:** I–V `"{rank} doink-to-good a quarter"`. VI `"5 doink-to-good a quarter, unused carry (max 5)"`. VII–XII and XIII–XXIV `"{effect_rank} doink-to-good a quarter, unused carry (max {effect_rank})"`, except VI's special line. Rank XII prints 12 and max 12.
- **actual effect:** I–V grant that many charges and do not carry. VI grants 5 and carries, cap 5. VII–XII grant `effect_rank` charges and carry up to that number. XIII–XXIV stay at 12.
- **match:** yes, ranks I–XXIV

### Drive Lid

- **id:** `drive_lid`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** none. XIII–XXIV use `_DRIVE_LATE`.
- **card text:** `"+{drive_yards} yd"`.
- **actual effect:** `range_bonus += drive_yards(rank)`. Big Game keeps it. Adds with Cannon Cleats and High-Air Gloves. Howling multiplies the sum by 1.15.
- **match:** yes, ranks I–XXIV

| Rank | Yards |
| --- | --- |
| I–XII | 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48 |
| XIII–XXIV | 61, 75, 90, 107, 126, 146, 167, 190, 214, 240, 268, 297 |

### True Lid

- **id:** `true_lid`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The factor stays the rank XII hundredths, 0.28.
- **card text:** `"Hook ×{true_lid_factor}"`. Rank I is ×0.90. Rank VI is ×0.53. Rank XII–XXIV is ×0.28.
- **actual effect:** `angle_scale` is multiplied by `true_lid_factor`, the hundredths of `0.90^effect_rank`. A second helmet does not write `angle_scale`. Big Game does not reset `angle_scale`.
- **match:** yes, ranks I–XXIV. The hook uses the printed hundredths.

### Shelter Lid

- **id:** `shelter_lid`
- **slot:** helmet
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The factor stays the rank XII table value, 0.28.
- **card text:** `"Headwind loss ×{shelter_factor_for}"`. Rank I is ×0.90. Rank VI is ×0.53. Rank XII–XXIV is ×0.28. Shelter does not change needle speed.
- **actual effect:** a negative wind-range term is multiplied by `shelter_factor_for(rank)` (`shelter_factor`). Tailwind is not reduced.
- **match:** yes, ranks I–XXIV. Card and code use the same table.

### Iron Grip

- **id:** `iron_grip`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** the red-tip switch is already fully off at VI (`effect_rank >= 6`). VII–XXIV do not change it. XIII–XXIV match XII.
- **card text:** I–II `"Red-tip noise −{2 × rank}"`. III–V name noise −4 and a later red-tip start. VI and above `"Red tip never triggers"`.
- **actual effect:** noise starts at 5. The cut is `2 × min(effect_rank, 2)`, floored at 1, so rank I is ±3 and rank II and up are ±1. Red-tip start begins at 95 and gains +3 at III, IV, and V (98, 101, 104). Rank VI and up set `red_tip_off`. Big Game restores the base red-tip values and clears `red_tip_off`.
- **match:** yes, ranks I–XXIV

### Replay Gloves

- **id:** `replay_gloves`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. Swings stay at 12 and the carry max stays at 12.
- **card text:** I–V `"{rank} practice swing a quarter"`. VI `"5 practice swings, unused carry (max 5)"`. VII and up use `effect_rank` for both the count and the carry max. XII–XXIV say 12 and max 12.
- **actual effect:** the same counts. `practice_carry` turns on at rank VI. Scout Lid's practice, a different slot, adds.
- **match:** yes, ranks I–XXIV

### High-Air Gloves

- **id:** `high_air_gloves`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** none. XIII–XXIV use `_AIR_LATE`.
- **card text:** `"+{high_air_yards} yd, tailwind range ×1.5"`.
- **actual effect:** `range_bonus += high_air_yards(rank)` and `thin_air` is set, so a positive wind-range term is ×1.5. The yards add with Cannon and Drive Lid.
- **match:** yes, ranks I–XXIV

| Rank | Yards |
| --- | --- |
| I–XII | 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24 |
| XIII–XXIV | 30, 37, 44, 52, 61, 71, 81, 92, 104, 116, 130, 144 |

### Guide Gloves

- **id:** `guide_gloves`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The hook factor stays 0.28.
- **card text:** `"GOOD locks: hook ×{0.50 − 0.02 × (effect_rank − 1)}"`. Rank I is ×0.50. Rank VI is ×0.40. Rank XII–XXIV is ×0.28.
- **actual effect:** `guide_factor` is that exact hundredth. A good-band miss uses it to shrink the hook. No other glove writes it.
- **match:** yes, ranks I–XXIV

### Patient Gloves

- **id:** `patient_gloves`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The factor stays the rank XII table value, 0.40.
- **card text:** `"Power needle ×{patient_factor}"`. Same table as Anchor. Rank I is ×0.85. Rank VI is ×0.58. Rank XII–XXIV is ×0.40.
- **actual effect:** only the power slow product is multiplied by `patient_factor(rank)`. The accuracy needle is not. Anchor, if also owned, multiplies both needles, so the power needle is hit twice. The combined item, perk, and vitamin slow is floored at 0.35. Big Game restores base power speed, so this mul is off during Big Game.
- **match:** yes, ranks I–XXIV. Card and code use the same table.

### Hush Gloves

- **id:** `hush_gloves`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. Ignored wind stays at 12 mph.
- **card text:** `"First {effect_rank} mph of wind ignored"`. Rank I is 1. Rank VI is 6. Rank XII–XXIV is 12.
- **actual effect:** `hush_mph` is subtracted from the blown wind speed before drift and wind range, floored at 0. Howling scales the wind vector before this subtraction.
- **match:** yes, ranks I–XXIV

### Weather Wraps

- **id:** `weather_wraps`
- **slot:** gloves
- **rank cap:** Standard VI, Endless XXIV
- **soft cap:** from XIII. The bonus stays +18 yards.
- **card text:** I halves rain, snow, and mud. II ignores those three. III also ignores Monsoon's rain and mud. IV and up `"Penalties ignored, +{2 × (effect_rank − 3)} yd unless CLEAR"`. Rank VI is +6. Rank XII–XXIV is +18.
- **actual effect:** `weather_cut` is 1, 2, then 3 from rank III up. `wraps_yards` is `2 × (effect_rank − 3)` from rank IV. That bonus is added in `prepare_kick_stats` when the weather is not CLEAR, and Howling multiplies that bonus by 1.15 before it is added.
- **match:** yes, ranks I–XXIV

### Deep Bench

- **id:** `deep_bench`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I–II `"Attempt cap +{rank} and attempts +{rank}"`. III `"Cap stays. +1 attempt now and each quarter if below cap"`. IV `"Cap stays. Halfway to +1 extra attempt. Spare stays."`. V `"+1 attempt cap and +1 attempt now. Spare stays."`. VI `"+1 more attempt cap and +1 attempt now. Spare stays."`.
- **actual effect:** `Loadout.apply` raises the cap by `min(rank, 2)` only, and sets the spare from rank III. Ranks IV–VI add cap through `give`'s bank: rank IV adds 0.5 toward an extra cap, rank V grants one cap and one attempt, rank VI grants one more. A save that stores `bench_extra_cap` keeps those grants on rebuild.
- **match:** yes, ranks I–VI

### Hot Streak

- **id:** `hot_streak`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"+0.5"`, II `"+0.75"`, III `"+1.0"`, IV `"+1.25"`, V `"+1.5"`, VI `"+1.75"`.
- **actual effect:** replaces the base step of 0.25 with 0.5, 0.75, then `1.0 + 0.25 × (rank − 3)`. The HUD Mult uses `1 + step × streak`, then Showtime's stored double.
- **match:** yes, ranks I–VI

### Storm Chaser

- **id:** `storm_chaser`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** `"+{0.2 × rank} Mult per mph of crosswind"` through VI (0.2, 0.4, 0.6, 0.8, 1.0, 1.2).
- **actual effect:** `storm_bonus` is `0.2 × rank` per mph of crosswind. Howling multiplies that rate by 1.15.
- **match:** yes, ranks I–VI

### Hero Ball

- **id:** `hero_ball`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** Mult +1.0, +1.5, +2.0, +2.5, +3.0, +3.5 at I–VI, and `"both needles ×0.80"` at every rank.
- **actual effect:** the Mult add matches the card. Both needles are multiplied by 0.80 at every rank. Big Game removes the needle slow and keeps the Mult. Howling multiplies the Mult by 1.15 and widens the 0.80 gap. Anchor and Patient multiply after this.
- **match:** yes, ranks I–VI

### Glass Leg

- **id:** `glass_leg`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** I `"+8 yd, attempt cap −1"`. II–VI `"+{8 × rank} yd total, no extra cap loss"`.
- **actual effect:** `range_bonus += 8 × rank` (8, 16, 24, 32, 40, 48). The attempt cap drops by 1 once, floored at 1, at every rank. The first take is refused when the cap is already 2 or less.
- **match:** yes, ranks I–VI

### Two-Minute Drill

- **id:** `two_minute_drill`
- **slot:** perk
- **rank cap:** Standard III, Endless VI
- **card text:** `"Boss kicks +{0.5 × rank} Mult, on top of ×1.5"` at I–VI (0.5 through 3.0).
- **actual effect:** `drill_bonus` is `0.5 × rank` and is added on top of the boss score multiplier. Howling multiplies the add by 1.15. It applies on every boss, including UNDER THE LIGHTS.
- **match:** yes, ranks I–VI

### Iced

- **id:** `iced`
- **slot:** curse
- **rank cap:** 1
- **card text:** `"Down: meter hides 0.4s after Space. Up: +0.75 Mult"`
- **actual effect:** +0.75 Mult. The meter hides 0.4 seconds after it starts. Ice Cage in either helmet slot blocks the hide and blocks taking this curse. The Mult is not multiplied by Howling's equipment ×1.10. Phil's scale does scale curse Mult.
- **match:** yes

### Shanky Cleats

- **id:** `shanky_cleats`
- **slot:** curse
- **card text:** `"Down: accuracy error ×1.5. Up: +1.0 Mult"`
- **actual effect:** `angle_scale` is multiplied by 1.5, and Mult gains 1.0. True Lid's hook reduction multiplies `angle_scale` as well, so the two factors multiply.
- **match:** yes

### Heavy Ball

- **id:** `heavy_ball`
- **slot:** curse
- **card text:** `"Down: −4 yd. Up: accuracy error ×0.85"`
- **actual effect:** travel loses 4 yards in `carry_plan`, and `angle_scale` is multiplied by 0.85. The −4 is not in the equipment Howling 1.15.
- **match:** yes

### Howling Wind

- **id:** `howling_wind`
- **slot:** curse
- **card text:** `"Down: wind ×1.5. Up: equipment and perks ×1.10"`
- **actual effect:** the wind vector is multiplied by 1.5 before Hush Gloves subtract. Equipment and perk additives listed above are multiplied by 1.10 after they are summed. Multiplier gaps are widened by 1.10. Both pieces of a doubled type are inside that sum. Curse upside yards are not in the 1.10. The Weather Wraps non-CLEAR yard bonus is multiplied by 1.10 on its own, before it is added.
- **match:** yes

### Shaky Arrow

- **id:** `shaky_arrow`
- **slot:** curse
- **card text:** `"Down: aim sways ±3°. Up: +10 yd"`
- **actual effect:** the aim mark sways, and `range_bonus` gains 10. That +10 is a curse upside, so Howling's equipment ×1.10 does not multiply it. Phil's scale does.
- **match:** yes

### Narrow Posts

- **id:** `narrow_posts`
- **slot:** curse
- **card text:** `"Down: posts 5.17 yd. Up: +0.75 Mult"`
- **actual effect:** `post_width` is 5.17 when this curse is owned or the weather is The Squeeze. UNDER THE LIGHTS does not narrow the posts. The +0.75 Mult is a curse upside.
- **match:** yes

### Stone Toe

- **id:** `stone_toe`
- **slot:** curse
- **card text:** `"Down: power needle ×1.20. Up: +10 yd"`
- **actual effect:** power speed is multiplied by 1.20. That is a faster needle, a downside. Big Game keeps this 1.20 and strips meter-help slows. UNDER THE LIGHTS multiplies after it, so the power needle is ×1.20 × 1.35. The +10 yards is a curse upside.
- **match:** yes

### Tight Window

- **id:** `tight_window`
- **slot:** curse
- **card text:** `"Down: PERFECT and good −2. Up: +1.0 Mult"`
- **actual effect:** both bands lose 2, floored at 1, and perfect is not allowed to exceed good. Big Game reapplies this shrink after it restores the kicker's base bands. The +1.0 Mult is a curse upside.
- **match:** yes

## 2. Vitamins and shop services

Belt vitamins are one use. They are not equipment. Card lines are `Vitamins.effect_line`.

| Id | Price | Card | Coded effect |
| --- | --- | --- | --- |
| `protein_shake` | 4 | `"+6 yd this kick"` | `range_bonus += 6`, then Phil's scale and `round_tenth` |
| `magnesium` | 4 | `"Needles ×0.7 this kick"` | both needle speeds ×0.7, gap-scaled if Phil or Lucky Ball is on |
| `omega_3` | 5 | good band wipes the angle; the +5 perfect score bonus turns off; the perfect cash dollar can still pay | sets `stats.omega` |
| `electrolyte_tabs` | 6 | `"A miss keeps the attempt"` | a miss does not spend an attempt, including a Bonus Ring miss |
| `vitamin_d` | 5 | `"Ignore rain, snow, and mud"` | clears rain, snow, and mud flags. Monsoon's extras are not in that clear |
| `pre_workout` | 4 | `"+0.5 Mult if this kick is made"` | +0.5 Mult on a make, scaled by Phil |
| `zinc` | 5 | `"Reroll this kick's wind and weather"` | one reroll of wind and weather, then the bottle is consumed. A second use says `"Already rerolled"` |
| `lutein` | 5 | `"Wind numbers and a full dotted path"` | `flag_reader`, `laser_line`, path percent at least 100 |
| `pickle_juice` | 5 | `"Sideways wind drift ×0.5"` | `drift_factor` ×0.5, gap-scaled |
| `tart_cherry` | 6 | `"Remove one curse"` | opens the curse picker. It does not enter the active vitamin list |
| `b12_shot` | 7 | `"+1 attempt"` | +1 attempt, once per shop visit, up to the cap. Not a belt item |

Shelf reroll starts at $2 and rises by $1 after each purchase. It is cash. Phil does not zero it. Sell pays half the price charged, rounded down. Phil's charged price is 0, so the refund is 0. A full belt shows `"Belt full: sell first"`.

### Shelf reroll

Matches the live price string `"Reroll ({key}): ${price}"`.

### Sell and a full belt

The belt has two slots. Sell is only in the shop. A buy without enough cash turns the price red and adds no words.

## 3. Kicker kits and balls

Base max range here is `carry_plan` at 100% power, 0 wind, no items, no weather penalty, kick distance 35 unless noted. Vex depends on the required distance. Perfect and good bands start at `1.5 × accuracy / 100` and `6 × accuracy / 100`.

| Kicker | Accuracy | Bands | 100% power, no items | Needle ball mult |
| --- | --- | --- | --- | --- |
| Big Bruce | 90 | ±1.35 / ±5.40 | 65 yd | 1.00 |
| The Walk-On | 100 | ±1.50 / ±6.00 | 60 yd | 1.00 |
| Phil The Pharmacist | 112 | ±1.68 / ±6.72 | 55 yd | 1.00 |
| Gary the Goat | 98 | ±1.47 / ±5.88 | 65 yd | 1.00 |
| Vex | 94 | ±1.41 / ±5.64 | kick distance + 20 yd | 1.00 |
| Cole Lang | 120 | ±1.80 / ±7.20 | 70 yd | 1.00 |
| Willow Reed | 88 | ±1.32 / ±5.28 | 50 yd | 0.50 |
| Carlos Hernandez | 96 | ±1.44 / ±5.76 | 66 yd | 1.15 |

Cole's ball multiplier is 1.00 in `Kickers.apply_to`. It is not 0.90. Carlos is 1.15. Willow is 0.50. Those multiply the needle omega on top of `power_speed` and `accuracy_speed`.

### Big Bruce

- **Select range:** `"65 yd"`
- **Kit text:** `"Farm Strength. A press under 80% still kicks at 80%."`
- **actual effect:** `power_floor` is 80. Full power is `16 + 0.49 × 100` = 65 yards before wind and items.
- **match:** yes
- **Ball:** `"The Farm Ball"`. Wind drift ×1.10. A doink stays a doink.
- **match:** yes

### The Walk-On

- **Select range:** `"60 yd"`
- **Kit text:** `"Earns His Spot. 2 rerolls a run."`
- **actual effect:** `rerolls_per_run` is 2. Full power is `16 + 0.44 × 100` = 60 yards. `ball_speed_mult` is 1.
- **match:** yes
- **Ball:** `"Team-Issue"`. No trick.
- **match:** yes

### Phil The Pharmacist

- **Select range:** `"55 yd"`
- **Kit text:** `"House Account. Shop goods are free, including B12. Shelf rerolls still cost cash. Compounding. Your items are 15% stronger: equipment, perks, curse upsides, and vitamins, not only shop bottles."`
- **actual effect:** full power is 55 yards. `item_price` is 0, including B12. The shelf reroll still costs cash. Item scale is 1.15 and hits equipment, perks, curse upsides, and vitamins, including both pieces of a doubled type.
- **match:** yes
- **Ball:** `"The Gelcap"`. One active ball vitamin adds +0.5 Mult once on a make. Not scaled by Compounding. Zinc and Tart Cherry do not count.
- **match:** yes

### Gary the Goat

- **Select range:** `"65 yd"`
- **Kit text:** `"Good As Gold. The good band counts as PERFECT."`
- **actual effect:** a good-band lock is a true perfect, including the perfect cash dollar. Full power is 65 yards. No power floor.
- **match:** yes
- **Ball:** `"Lucky Ball"`. Each first-try make adds 3% item scale for the rest of the run. A miss does not. A Bonus Ring miss clears the first-ball flag, so the later make of that kick does not add a stack.
- **match:** yes

### Vex

- **Select range:** `"Infinite Range & Beyond"`
- **Kit text:** `"Infinite Range & Beyond. 88% power clears by 5 yards."`
- **actual effect:** travel is `kick distance + 5 + (power − 88) × 1.25`, plus items and wind. At 88% with no wind the clearance is 5 yards. At 100% it is 20 yards. If power is at least 88 and a headwind or a penalty would leave the ball short, travel is raised only back to the kick distance, not back up to a 5-yard clearance.
- **match:** mismatch. A headwind, snow, or Heavy Ball can shrink the 5-yard clearance down to just reaching the posts.
- **Ball:** `"The Flying Saucer"`. 8 mph is subtracted from the crosswind before drift and wind range. Howling then scales the combined vector.
- **match:** yes

### Cole Lang

- **Select range:** `"70 yd"`
- **Kit text:** `"Brand Deal. Loadout offers stay. The Vitamin Shop does not."`
- **actual effect:** `follow_offer` skips the shop. The loadout offer still runs. Full power is `16 + 0.54 × 100` = 70 yards. `ball_speed_mult` is 1.00.
- **match:** yes
- **Ball:** `"Showtime"`. A down-the-middle make doubles the Mult used for that score and doubles the stored Showtime factor afterward. A miss sets the stored factor back to 1.
- **match:** yes

### Willow Reed

- **Select range:** `"50 yd"`
- **Kit text:** `"Synchronicity. The first loadout offer includes a range item."`
- **actual effect:** the first generated offer of the run swaps in Cannon, Drive Lid, High-Air, or Glass Leg at rank I when that card is legal. Later offers and rerolls are normal. It does not force a shop bottle. Full power is `16 + 0.34 × 100` = 50 yards.
- **match:** yes
- **Ball:** `"The Chill Ball"`. `ball_speed_mult` is 0.50. Items and weather still stack on top, including UNDER THE LIGHTS ×1.35.
- **match:** yes

### Carlos Hernandez

- **Select range:** `"66 yd"`
- **Kit text:** `"Numero Dos. A 95–100 lock is a true PERFECT."` A power of 94 or below is a normal accuracy swing.
- **actual effect:** power from 95 through 100 forces accuracy error to 0 and `perfect` true. An auto-shank never reaches this check. Full power is `16 + 0.50 × 100` = 66 yards.
- **match:** yes
- **Ball:** `"The Not So Secret Weapon"`. `ball_speed_mult` is 1.15. Items and weather still multiply on top.
- **match:** yes

## 4. Max-range formula

`carry_plan` at 0 wind, confirmed headless on 2026-11-14. Order:

1. Wind vector. Vex subtracts 8 mph from the crosswind. Howling multiplies the combined speed by 1.5. Hush Gloves then subtract mph, floored at 0.
2. Wind range is `head_or_tail mph × 0.4`. High-Air multiplies a positive change by 1.5. Shelter Lid multiplies a negative change by `shelter_factor`.
3. Vex: `travel = kick distance + 5 + (power − 88) × 1.25 + range_bonus + wind range`.
4. Everyone else: `travel = 16 + range_per_power × power + range_bonus + wind range`.
5. Snow, thin air (+4), and Heavy Ball (−4) apply after that.
6. If Vex is at 88% or more and travel is still short of the posts, travel is raised to the kick distance.

Worked examples, 100% power, 0 wind, no vitamin, no Howling, no Phil:

| Build | Travel |
| --- | --- |
| Big Bruce, no items | 65 yd |
| Big Bruce, Cannon VI | 101 yd |
| Big Bruce, Cannon XII | 137 yd |
| Big Bruce, Cannon XXIV | 506 yd |
| Big Bruce, Drive Lid VI | 89 yd |
| Big Bruce, Drive Lid XII | 113 yd |
| Big Bruce, Drive Lid XXIV | 362 yd |
| Big Bruce, Cannon XXIV + Drive Lid XXIV | 803 yd |
| Willow, Cannon XXIV + Drive Lid XXIV | 788 yd |
| Cole, Cannon XXIV + Drive Lid XXIV | 808 yd |
| Cole, Cannon + Drive + High-Air, all XXIV | 952 yd |
| Cole, those three plus Glass Leg VI, Shaky Arrow, Stone Toe, and Protein | 1026 yd |
| Cole, same helpers with High-Air XVIII | 953 yd |

No two styles in one equipment type both add range. Cannon, Drive Lid, and High-Air are three different types, and their yards add. Bruce with all three at XXIV is 65 + 441 + 297 + 144 = 947 yards. That is still short of 1000. The make needs Glass Leg VI, Shaky Arrow, Stone Toe, and a Protein Shake on top.

Vex, no items, 100% power, kick distance 35: 55 yd (35 + 20). The same kick at distance 50: 70 yd.

## 5. Cash and Vitamin Shop rules

Cash starts at 0. It is not written into the save.

`cash_payout` pays 0 on a miss, including a Bonus Ring collect. A make pays 3, plus 1 if perfect, plus 1 if down the middle, plus 2 if it was a boss. Those stack. Omega-3 can suppress the +5 perfect score bonus and still leave the perfect dollar. Gary's Good As Gold makes a good-band lock count as perfect for that dollar.

Standard shops open after a make on kick 5, 10, or 15. Endless shops open after a make on every kick number divisible by 5 (5, 10, 15, 20, 25, and so on). Cole's Brand Deal skips the shop. The loadout offer still happens.

The first shelf reroll of a visit is $2 and each purchase adds $1. Phil does not zero that. B12 is $7 unless Phil is playing, once per visit, and it does not use a belt slot.

## 6. Bosses and item interactions

Boss weather is the condition name. Wind still comes from the kick table. Retries keep the rolled boss.

| Boss | Where | What the code changes | Items |
| --- | --- | --- | --- |
| Iced | Standard kick 5. Endless pool. | Meter hides the way the Iced curse does, unless Ice Cage or Ice Veins is on. | Ice Cage blocks the hide. No needle multiplier. |
| The Squeeze | Standard kick 10, 50/50 with UNDER THE LIGHTS. Endless pool. | Posts are 5.17 yards wide. | Narrow Posts does not stack a second shrink. No needle multiplier. |
| Monsoon | Standard kick 15. Endless pool. | Rain and mud together. Weather Wraps rank III ignores both. | Vitamin D clears plain rain, snow, and mud, not the Monsoon extras. |
| Big Game | Standard kick 20. Endless pool. | Meter-help is stripped. Needle speeds, bands, and red-tip flags are copied from the bare kicker. Vitamins then join the slow product and the 0.35 floor. Stone Toe's ×1.20 power needle applies after that floor. Tight Window's −2 bands are applied again. Range gear is kept. | Anchor, Patient Gloves, Hero Ball's needle slow, and Ice Cage's band adds are off. Magnesium still slows. UNDER THE LIGHTS is not this boss, so it does not strip meter help. |
| UNDER THE LIGHTS | Standard kick 10, the other half of the roll, stored at `new_run` so the kick 5 shop matches. Endless pool. | Both needles ×1.35 after the 0.35 slow floor, and after Stone Toe. Rain still multiplies accuracy omega after that. Posts stay 6.17. Wind is the kick 10 table (10–15 mph in Standard). No rain, snow, or mud from the boss itself. The beams are visual only. Practice Swing does not get the ×1.35. | Meter-help items stay on. Two-Minute Drill still adds its boss Mult. The ×1.35 is not floored. |

The kick 10 roll uses its own generator, so it does not shift the weather sequence. Debug Shift+9 forces UNDER THE LIGHTS until the kick is left. Shift+6 is still The Squeeze.

Needle rate is built in `MeterGauge.needle_speed`. Item, perk, and vitamin slows multiply first and floor at 0.35. Then Stone Toe ×1.20, UNDER THE LIGHTS ×1.35, rain, and ball speed. Stored speeds below are after `prepare_kick_stats`, so they include the floor, Stone Toe, and the lights, and not rain or ball speed. The live rate also multiplies `ball_speed_mult` (Walk-On 1, Cole 1, Carlos 1.15).

| Build | Power speed | Accuracy speed | Live rate vs a bare Walk-On |
| --- | --- | --- | --- |
| Walk-On, no items | 100 | 120 | 1.00 |
| Walk-On, UNDER THE LIGHTS | 135 | 162 | 1.35 |
| Walk-On, lights + Anchor VI | 78.3 | 93.96 | 0.783 |
| Walk-On, lights + Anchor XII or XXIV | 54 | 64.8 | 0.54 |
| Walk-On, Anchor XII + Patient XII | 35 | 48 | 0.35 |
| Walk-On, that pair under the lights | 47.25 | 64.8 | 0.4725 |
| Carlos, no items | 100 | 120 | 1.15 |
| Carlos, UNDER THE LIGHTS | 135 | 162 | 1.5525 |
| Carlos, lights + Anchor XXIV | 54 | 64.8 | 0.621 |
| Cole, no items | 100 | 120 | 1.00 |
| Cole, UNDER THE LIGHTS | 135 | 162 | 1.35 |
| Cole, lights + Anchor XXIV | 54 | 64.8 | 0.54 |

Anchor XII is ×0.40 on both needles, and XXIV copies it. Patient XII is ×0.40 on power only. Together the power slow is 0.16, which the floor raises to 0.35. UNDER THE LIGHTS then multiplies that 0.35 by 1.35. Hero Ball's ×0.80 is a slow and goes through the same floor.

## 7. Balance sheet

Blank cells are ranks that item cannot reach. "Next rank adds nothing" is the first rank where the coded gain is 0, or under 5% of the previous rank's gain. Cannon, Drive, and High-Air never hit that inside I–XXIV. Their late steps stay large.

### Equipment

| Item | Boosts | I | VI | XII | XXIV | Shape | First flat or tiny step |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cannon Cleats | range yards | +6 | +36 | +72 | +441 | flat +6 through XII, then the BAL2 late table | none through XXIV |
| Pinpoint Cleats | perfect / good bands | +2 / +3 | +12 / +18 | +24 / +36 | same as XII | flat +2 / +3 per rank, then capped | XIII |
| Anchor Cleats | both needle speeds | ×0.85 | ×0.58 | ×0.40 | same as XII | BAL1 table, then capped. Slow floor 0.35 can raise a stack | XIII |
| Sticker Cleats | drift | ×0.90 | ×0.53 | ×0.28 | same as XII | BAL1 table, then capped | XIII |
| Wind Visor | wind readout, path percent | readout, 0% path | 100% path | 100% path | 100% path | path rises through VI, then flat | VII |
| Ice Cage | red-tip off, Iced block, accuracy ×0.90, bands | immunity | ×0.90, +2 / +4 | ×0.90, +5 / +10 | same as XII | bands rise through XII, then capped | XIII |
| Scout Lid | rerolls, practice | +1 reroll | +5 rerolls, 2 practice | +11 rerolls, 5 practice | same as XII | rises through XII, then capped | XIII |
| Doink Cap | doink-to-good charges | 1 | 5, carry 5 | 12, carry 12 | same as XII | rises through XII, then capped | XIII |
| Drive Lid | range yards | +4 | +24 | +48 | +297 | flat +4 through XII, then the BAL2 late table | none through XXIV |
| True Lid | hook factor | ×0.90 | ×0.53 | ×0.28 | same as XII | hundredths of 0.90^rank, then capped | XIII |
| Shelter Lid | headwind loss | ×0.90 | ×0.53 | ×0.28 | same as XII | BAL1 table, then capped | XIII |
| Iron Grip | red-tip noise and start, then off | noise −2 | red tip off | red tip off | red tip off | noise caps at II, off switch at VI | VII |
| Replay Gloves | practice swings | 1 | 5, carry 5 | 12, carry 12 | same as XII | rises through XII, then capped | XIII |
| High-Air Gloves | range yards, tailwind ×1.5 | +2 | +12 | +24 | +144 | flat +2 through XII, then the BAL2 late table. Tailwind stays ×1.5 | none through XXIV |
| Guide Gloves | good-lock hook | ×0.50 | ×0.40 | ×0.28 | same as XII | flat −0.02 per rank, then capped | XIII |
| Patient Gloves | power needle | ×0.85 | ×0.58 | ×0.40 | same as XII | BAL1 table, then capped. Slow floor 0.35 can raise a stack | XIII |
| Hush Gloves | wind mph ignored | 1 | 6 | 12 | same as XII | flat +1 mph, then capped | XIII |
| Weather Wraps | weather cut, then yards | half penalties | ignore + 6 yd | ignore + 18 yd | same as XII | +2 yd per rank from IV, then capped | XIII |

### Perks

| Item | Boosts | I | VI | XII | XXIV | Shape | First flat step |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deep Bench | attempt cap, spare | cap +1 | another cap on top of V | | | rises at I, II, V, VI; IV is half a cap | none inside I–VI |
| Hot Streak | streak step | 0.50 | 1.75 | | | +0.25 per rank after II | none inside I–VI |
| Storm Chaser | mult per crosswind mph | 0.2 | 1.2 | | | flat +0.2 per rank | none inside I–VI |
| Hero Ball | mult, both needles ×0.80 | +1.0 | +3.5 | | | +0.5 mult per rank after I; needle slow is flat | needle slow is flat at every rank |
| Glass Leg | yards, cap −1 once | +8 yd, cap −1 | +48 yd | | | flat +8 yd; the cap loss does not repeat | cap loss adds nothing from II |
| Two-Minute Drill | boss mult | +0.5 | +3.0 | | | flat +0.5 per rank | none inside I–VI |

### Curses

| Item | Downside | Upside |
| --- | --- | --- |
| Iced | meter hides 0.4 s after Space, unless Ice Cage | +0.75 Mult |
| Shanky Cleats | accuracy error ×1.5 | +1.0 Mult |
| Heavy Ball | −4 yd | accuracy error ×0.85 |
| Howling Wind | wind ×1.5 | equipment and perks ×1.10 |
| Shaky Arrow | aim sways ±3° | +10 yd |
| Narrow Posts | posts 5.17 yd | +0.75 Mult |
| Stone Toe | power needle ×1.20 | +10 yd |
| Tight Window | perfect and good −2 | +1.0 Mult |

### Vitamins

| Item | Boosts | Effect | Shape |
| --- | --- | --- | --- |
| Protein Shake | range | +6 yd this kick | one rank |
| Magnesium | both needles | ×0.7 this kick | one rank |
| Omega-3 | angle, perfect score | good band wipes the angle; +5 perfect score bonus off | one rank |
| Electrolyte Tabs | attempt | a miss keeps the attempt | one rank |
| Vitamin D | weather | ignore rain, snow, and mud | one rank |
| Pre-Workout | mult | +0.5 on a make | one rank |
| Zinc | wind and weather | one reroll | one rank |
| Lutein | wind display | mph line and a full path | one rank |
| Pickle Juice | drift | ×0.5 | one rank |
| Tart Cherry | curse | remove one | one rank |
| B12 Shot | attempt | +1, once per shop visit | one rank |

### Rank redundancy

- Wind Visor: the path is already the full flight at VI. Ranks VII–XXIV add no path and no readout. BAL2 leaves this.
- Iron Grip: the red tip is already off at VI. Ranks VII–XXIV add nothing. BAL2 leaves this.
- Every other equipment style changes from XIII through XXIV. Count items take a half step. Shield styles keep the XII multiplier and add +1 yd per rank.
- Glass Leg: the attempt-cap loss happens once. Ranks II–VI add yards only.
- Hero Ball: the ×0.80 needle slow does not change after rank I. Later ranks add Mult only.

### Outliers

Coded size at the top rank that item can reach, next to others in the same slot. No recommendation.

- Cannon XXIV is +441 yards. Drive Lid XXIV is +297. High-Air XXIV is +144 plus tailwind ×1.5.
- Anchor XXIV is still ×0.40 and also +12 yd. Sticker, True Lid, Shelter, Guide, Patient, and Hush follow the same +1 yd pattern on top of their XII effect.
- Scout Lid XXIV is 17 rerolls and 5 practice swings. Doink Cap and Replay Gloves reach 18. Weather Wraps reaches +30 yd. Pinpoint XXIV is +36 PERFECT and +54 good. Ice Cage XXIV is +11 PERFECT and +22 good.
- Glass Leg VI is +48 yards. Two-Minute Drill VI is +3.0 boss Mult. Hot Streak VI is a 1.75 streak step. Those are the perk yard and mult extremes.
- Anchor XII (and XXIV) multiplies both needles by 0.40. Hero Ball multiplies both by 0.80 at every rank. Patient Gloves reach 0.40 on the power needle only. A stack of those slows cannot go below 0.35 before the speed-ups.
- Stone Toe still speeds the power needle (×1.20) and now pays +10 yards. Shaky Arrow also pays +10 yards. Iced and Narrow Posts pay +0.75 Mult. Shanky Cleats and Tight Window pay +1.0 Mult. Howling Wind boosts items by ×1.10. Heavy Ball's accuracy-error upside is still ×0.85.

## 8. Mismatch index

Fixed since 2026-11-12, and not repeated below: perk cards IV–VI, Wind Visor mph line, Ice Cage cumulative line, Scout Lid, Doink Cap, Replay Gloves, and Weather Wraps ranks past VI, Willow's shop-vitamin sentence, and Phil's "shop items only" sentence.

BAL1 closed the rounding gaps. Anchor, Patient, Sticker, and Shelter use lookup tables, and the card prints that table. True Lid's hook uses the hundredths already printed on the card. XIII–XXIV of each of those five still copy XII, on the card and in the code.

- `vex` kit line: `"88% power clears by 5 yards."` That is the no-wind number. A headwind, snow, or Heavy Ball can shrink the clearance, down to just reaching the posts. BAL1 does not change kit text.
