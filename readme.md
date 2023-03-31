# Flogger

*"What's this shit, standing around *watching* the game? Get in there, put a helmet on, and hurt somebody."*

– George Carlin, Playin' with Your Head (1986)

**Flogger** for <a href="https://github.com/kolmafia/kolmafia">KoLmafia</a> caches your pvp fites and adds win rate and stance frequency statistics to the Huggler Memorial Colosseum Information Booth. (If you're caching a LOT of fites and need to pause, you cancel the script from KoLmafia with Escape -- your caching progress will always be saved.)

Try it out: `svn checkout https://github.com/DamianDominoDavis/kol-flogger/trunk/release/`

##### CLI Settings:
- `flogger help` — print these messages
- `flogger history` — adjust the number of fresh fites to review
- `flogger purge` — empty the cache and prepare to rescan
- `flogger backup` — copy cache to a backup safe from `purge`
- `flogger recolor` — cycle display colors

<a href="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/main/example.png?raw=true"><img alt="Example" src="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/main/example.png?raw=true" width="650" height="646"/></a>

##### Roadmap:
1. Requested: track loot gained, loot lost 
2. add name/ID filter box to archive page
3. fix compact mode