> "You know, what's this shit, standing around watching the game?<br />
> Get in there, put a helmet on and hurt somebody for Chrissakes, will you?<br />
> You're not getting paid to watch!"<br />

<sup>– George Carlin, "Sports", *Playin' with Your Head*, 1986</sup>

# Flogger
is a relay script for <a href="https://github.com/kolmafia/kolmafia">KoLmafia</a> that aggregates PvP win rate and mini frequency statistics. Run it by selecting Flogger from the drop-down in your relay browser's top menu: Flogger will start copying fights it hasn't seen yet into local storage, and display a summary when it's done. Find out what you're good at, focus on what you're not, and/or enjoy.

Try it out with CLI `git checkout DamianDominoDavis/kol-flogger release`

<img alt="Example" src="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/main/example.png" style="max-width: 100%;" />

##### FAQ:
- ***Why isn't anything happening when I pick Flogger from the top menu?***<br />
It probably is happening. If you haven't run Flogger before, or haven't run it in a while, you might have a whole huggy bunch of pvp fights Flogger hasn't scanned yet. But you can always wander off and do something else: Flogger will always save scan progress, even if interrupted by combat or a choice. Try loading again in a minute.

- ***What is Favor?***<br />
Favor measures variance from expected mini frequency, normalized to a scale of ±10. Positive favor means a mini is more popular to attack with than average; negative, less. (If you ever see Favor with a magnitude greater than 10, you've found a bug and should drop me a line.) Defensive Favor is a good indicator of which minis are popular.

- ***Will Flogger attack for me?***<br />
Though it suggests which mini is your best offense, Flogger is not for automating attacks. If you want a smart attack script, you want <a href="https://github.com/Pantocyclus/PVP_MAB">PVP_MAB</a>. (I enjoy the `no_optimize` parameter.)

##### CLI Settings:
- `flogger help` — print these messages
- `flogger history` — adjust for how many most recent fights to show stats
- `flogger purge` — empty the cache and prepare to rescan
- `flogger backup` — copy cache to a backup safe from `purge`
- `flogger recolor` — change colorblind modes

##### Roadmap:
1. show summary of gained/lost loot
2. move CLI controls to relay form
3. filter stats by opponent
