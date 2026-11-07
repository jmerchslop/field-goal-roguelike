# Field Goal

A run of 20 kicks, from 35 yards out to 75. Aim the arrow, press Space three times, and the game tells you GOOD or a miss.

## Play

1. Install [Godot 4](https://godotengine.org/download).
2. Open `project.godot`.
3. Press Play (F5).

The window is 1280×720. You stand behind the kicker and look up the field. 1 yard in the rules is 1 yard on the field. The kicker is a placeholder; a real picture can replace `scenes/kicker.tscn` later.

## Controls

- Hold **Left** or **Right** to aim. This only works before the meter starts.
- **Space** starts the meter, locks power, locks accuracy, then goes to the next kick.
- **R** starts a new run from the game over or win screen.
- After a **make**, press **1**, **2**, or **3** to take a card (or click it). **S** skips for 10 points. **F** rerolls. A miss does not offer cards.
- **M** uses a mulligan after a miss. Space accepts that miss instead.
- **W** sets this kick's wind to 10 mph, blowing right. **P** takes a practice swing if you own that card and still have one this quarter.

You begin by picking Big Bruce or The Walk-On. You start with 1 attempt and can hold 3. A make on the first try of a kick earns one, until the cap. A miss spends one and you kick that same spot again, with the same wind. No attempts left ends the run. Making kick 20 wins. The top-left line shows the kick, the distance, the score, the streak, the multiplier, and the attempt circles.

Wind is rolled when a kick first comes up, and a miss keeps it. A flag by the posts shows Calm, Breezy, Windy, or GALE. The ball bends late, toward the way the wind blows. A tailwind adds range and a headwind takes some away. Big Bruce's ball drifts less.

The needle on the right goes up for power, then down for accuracy. The green line is 0. The band labeled PERFECT is a perfect kick. The red tip at the top (95 to 100) adds a random wobble, so full power can knock a centered press out of PERFECT.

How far the ball flies is the power you just locked: 16 + 0.67 × P, plus any range bonus, and Big Bruce uses 0.75 instead of 0.67. If that distance is short of the kick, the ball drops there and the result is SHORT. If it is long enough, the ball goes through the posts and keeps going. The result line shows the power, the max range, and the kick distance.

## Which way the ball goes

Negative degrees are screen-left. Holding Left aims down to **-12°**. Holding Right aims up to **+12°**.

A positive accuracy number also pulls the ball left (a hook). A negative one pushes it right (a slice). The result line uses that same sign, so `angle = -1.1°` means a little to the left.

Kick 1 starts **35 yards** out, centered. Later kicks move the ball back, and hash or wide kicks also start off to one side. The arrow still begins pointing straight up the field, not at the posts. The first three kicks are calm and clear. After that the wind and the weather are rolled for that kick and kept if you miss. Boss kicks are ICED, THE SQUEEZE, MONSOON, and BIG GAME. The camera stays with your spot, so a kick from the left shows the posts to the right.

## Files

- `project.godot` — open this in Godot.
- `scenes/main.tscn` — the one scene Play runs.
- `scripts/KickConstants.gd` — every tunable number (speeds, distance, sizes, colors).
- `scripts/KickLogic.gd` — the rules of one kick, with no drawing.
- `scripts/RunTable.gd` — the 20 kicks (distance, spot, wind, conditions).
- `scripts/RunLogic.gd` — attempts, score, wind, and when the run ends. No drawing.
- `scripts/Upgrades.gd` — the upgrade cards. They are offered only after a make.
- `scripts/Kickers.gd` — Big Bruce and The Walk-On.
- `scripts/main.gd` — draws the field and reads the keyboard.
- `scripts/ScreenshotDriver.gd` — not used in normal play. It saves pictures when the game is started with `FG_SHOTS=1`.
- `tests/run_tests.gd` — checks the rules. From the project folder: `godot --headless --path . --script res://tests/run_tests.gd`
