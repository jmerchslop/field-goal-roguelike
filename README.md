# Field Goal

One kick. Aim the arrow, press Space three times, and the game tells you GOOD or a miss.

## Play

1. Install [Godot 4](https://godotengine.org/download).
2. Open `project.godot`.
3. Press Play (F5).

The window is 1280×720. Shapes stand in for art: a green field, yellow posts, a brown ball.

## Controls

- Hold **Left** or **Right** to aim. This only works before the meter starts.
- **Space** starts the meter, locks power, locks accuracy, then kicks again after the result.

The needle on the right goes up for power, then down for accuracy. The green line is 0. The band labeled PERFECT is a perfect kick. The red tip at the top (95 to 100) adds a random wobble, so full power can knock a centered press out of PERFECT.

## Which way the ball goes

Negative degrees are screen-left. Holding Left aims down to **-12°**. Holding Right aims up to **+12°**.

A positive accuracy number also pulls the ball left (a hook). A negative one pushes it right (a slice). The result line uses that same sign, so `angle = -1.1°` means a little to the left.

The ball starts **35 yards** from the posts. That distance is `kick_distance` in `scripts/KickLogic.gd`, so a later version can move the ball without rewriting the kick.

## Files

- `project.godot` — open this in Godot.
- `scenes/main.tscn` — the one scene Play runs.
- `scripts/KickConstants.gd` — every tunable number (speeds, distance, sizes, colors).
- `scripts/KickLogic.gd` — the kick rules, with no drawing, so they can be tested on their own.
- `scripts/main.gd` — draws the field and reads the keyboard.
- `scripts/ScreenshotDriver.gd` — not used in normal play. It saves three pictures when the game is started with `FG_SHOTS=1`.
- `tests/run_tests.gd` — checks the rules. From the project folder: `godot --headless --path . --script res://tests/run_tests.gd`
