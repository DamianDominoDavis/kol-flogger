# Flogger

*You might not be a winner at everything, you might not be a loser at everything; but you won't find out what you're good at if they tell you you're good at everything.*

**Flogger** for <a href="https://github.com/kolmafia/kolmafia">KoLmafia</a> adds win rate  and stance frequency statistics when you visit the Information Booth in the relay browser. Cached fights load instantly from your local /data, and then Flogger cache up to 200~500 new fights per minute. (You cancel early from KoLmafia with Escape, if you need to, and your cache progress will still be saved.)

Try it out! `svn checkout https://github.com/DamianDominoDavis/kol-flogger/trunk/release/`

##### CLI Settings:
- `flogger backup` -- copy cache to a backup
- `flogger help` -- print these messages
- `flogger history` -- toggle calculating only the last 1000 fites / all cached fites
- `flogger purge` -- empty the cache
- `flogger recolor` -- change colorblind modes

<a href="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/6c9f85f9e2786a58a84622f75e4776689a243025/example.png"><img alt="Example" src="https://raw.githubusercontent.com/DamianDominoDavis/kol-flogger/6c9f85f9e2786a58a84622f75e4776689a243025/example.png" width="697" height="673"/></a>

##### Roadmap:
1. fix history mode, currently broken?
	* separate caching and scoring phases, that should do it
2. add winningness, loot gained, loot lost to tracking
	* stats lost currently reports as stats gained
	* reminder: winningness is random attacks minus random losses, and a recorded fight was a random attack if nobody gained or lost fame
3. add a filter box to the archive page
	* filter on name or on playerID, use js/css to toggle elements