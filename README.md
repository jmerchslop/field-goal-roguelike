# Field Goal

A run of 20 kicks, from 35 yards out to 75. Aim the arrow, press Space three times, and the game tells you GOOD or a miss.

## Play

1. Install [Godot 4](https://godotengine.org/download).
2. Open `project.godot`.
3. Press Play (F5).

The window is 1280×720. Shapes stand in for art: a green field, yellow posts, a brown ball.

## Controls

- Hold **Left** or **Right** to aim. This only works before the meter starts.
- **Space** starts the meter, locks power, locks accuracy, then goes to the next kick.
- **R** starts a new run from the game over or win screen.

You begin with 1 attempt and can hold 3. A make on the first try earns one, until the cap. A miss spends one. No attempts left ends the run. Making kick 20 wins. The top-left line shows the kick, the distance, the score, the streak, the multiplier, and the attempt circles.

The needle on the right goes up for power, then down for accuracy. The green line is 0. The band labeled PERFECT is a perfect kick. The red tip at the top (95 to 100) adds a random wobble, so full power can knock a centered press out of PERFECT.

## Which way the ball goes

Negative degrees are screen-left. Holding Left aims down to **-12°**. Holding Right aims up to **+12°**.

A positive accuracy number also pulls the ball left (a hook). A negative one pushes it right (a slice). The result line uses that same sign, so `angle = -1.1°` means a little to the left.

Kick 1 starts **35 yards** out, centered. Later kicks move the ball back, and hash or wide kicks also start off to one side. The arrow still begins pointing straight up the field, not at the posts. Wind is listed in the kick table and is not used yet.

## Files

- `project.godot` — open this in Godot.
- `scenes/main.tscn` — the one scene Play runs.
- `scripts/KickConstants.gd` — every tunable number (speeds, distance, sizes, colors).
- `scripts/KickLogic.gd` — the rules of one kick, with no drawing.
- `scripts/RunTable.gd` — the 20 kicks (distance, spot, wind, conditions).
- `scripts/RunLogic.gd` — attempts, score, and when the run ends. No drawing.
- `scripts/main.gd` — draws the field and reads the keyboard.
- `scripts/ScreenshotDriver.gd` — not used in normal play. It saves pictures when the game is started with `FG_SHOTS=1`.
- `tests/run_tests.gd` — checks the rules. From the project folder: `godot --headless --path . --script res://tests/run_tests.gd`
