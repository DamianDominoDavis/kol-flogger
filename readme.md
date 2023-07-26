# Flogger

"What's this shit, standing around watching the game? Get in there, put a helmet on, and hurt somebody."

– George Carlin, "Sports", *Playin' with Your Head*, 1986

**Flogger** is a relay script for <a href="https://github.com/kolmafia/kolmafia">KoLmafia</a> wchich caches your pvp fites and shows win rate and stance frequency statistics. (If you're caching a LOT of new fites, there will be a pause. If you need to, you can cancel the script from the KoLmafia interface with Escape – your cache progress will always be saved.)

Try it out: `svn checkout https://github.com/DamianDominoDavis/kol-flogger/trunk/release/`

##### CLI Settings:
- `flogger help` — print these messages
- `flogger history` — adjust the number of fresh fites to review
- `flogger purge` — empty the cache and prepare to rescan
- `flogger backup` — copy cache to a backup safe from `purge`
- `flogger recolor` — cycle display colors

<a href="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/main/example.png"><img alt="Example" src="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/main/example.png" style="max-width: 100%;" /></a>

##### Roadmap:
1. Requested: track loot gained, loot lost 
2. add name/ID filter box to archive page
