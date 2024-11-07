record fite {
	int opponent;
	boolean attacking;
	string[string] rounds;
	int fame;
	int substats;
	int swagger;
	item prize;
};

boolean[int] debug_fite_ids = $ints[1403328];

string stance_name(string s) {
	static string[string] cache = {"" : "[ nameless ]"};
	if (!(cache contains s)) {
		string stripped = (s.length() > 1 && s.char_at(s.length()-1) == "*") ? s.substring(0, s.length()-1) : s;
		if (!($strings[Purrrity,Thirrrsty forrr Booze] contains stripped))
			stripped = stripped.replace_string("Rrr","R").replace_string("rrr","r");
		if ($strings[Visiting The Co@^&amp;$`~] contains stripped)
			stripped = stripped.entity_decode();
		stripped = stripped.replace_string("†","").replace_string("&#8224;","").replace_string("&dagger;","");
		stripped = stripped.replace_string("‡","").replace_string("&#8225;","").replace_string("&Dagger;","");
		stripped = stripped.replace_string("&apos;","'").replace_string("&#39;","'");
		cache[s] = stripped;
	}
	return cache[s];
}

// minified stance "enum"
static string[string] stance_bimap;
if (stance_bimap.count() < 1) {
	buffer info = visit_url("peevpee.php?place=rules", false);
	foreach k,s in info.xpath("//table//table//table//tr/td[1]/b/text()") {
		stance_bimap[k.to_string("%X")] = stance_name(s);
		stance_bimap[stance_name(s)] = k.to_string("%X");
	}
}

// minified fitestring
string as_string(fite f) {
	string out = f.opponent + (f.attacking? "a":"d") + " ";
	foreach mini,winner in f.rounds
		out += stance_bimap[mini] + winner;
	return out + ` {f.fame} {f.substats} {f.swagger} {f.prize}`;
}

string win_lose_draw(boolean attacking, boolean attacker_win, boolean defender_win) {
	if (attacker_win && defender_win)
		abort("double wins are draws? something is wrong");
	if (attacker_win || defender_win)
		return (attacking == attacker_win) ? "W" : "L";
	return "D";
}

int tally(fite f, string r) {
	if (f.rounds.count() < 7)
		abort(`error tallying fite {f.as_string()}`);
	int n = 0;
	foreach mini, result in f.rounds
		if (result == r)
			n++;
	return n;
}

boolean won(fite f) {
	int w = f.tally("W");
	int l = f.tally("L");
	return w > l + to_int(f.attacking);
}

boolean flawless(fite f) {
	return f.attacking && f.tally("W") == 7;
}

// fite constructor, takes uids from pvp log page links
fite examine_fite(int lid, boolean debug) {
	fite out;
	buffer buf = visit_url("peevpee.php?action=log&ff=1&lid="+lid+"&place=logs&pwd", false);
	string[int] playerids, fighters, stances, attacker_results, defender_results;

	if (buf.xpath("//div[@class='fight']").count() <= 0) // require expanded mode
		abort("Turn off compact mode in your vanilla KOL options.");
	playerids = buf.xpath("//div[@class='fight']/a/@href");
	fighters = buf.xpath("//div[@class='fight']/a/text()");
	stances = buf.xpath("//tr[@class='mini']/td/center");
	attacker_results = buf.xpath("//tr[@class='mini']/td[1]");
	defender_results = buf.xpath("//tr[@class='mini']/td[3]");
	out.attacking = (my_name().to_lower_case() == fighters[0].to_lower_case());

	out.opponent = (out.attacking ? playerids[1] : playerids[0]).split_string("=")[1].to_int();
	foreach i in stances {
		stances[i] = stances[i].xpath("//b/text()")[0].stance_name();
		out.rounds[stances[i]] = win_lose_draw(out.attacking, attacker_results[i].contains_text("youwin"), defender_results[i].contains_text("youwin"));
	}
	string[int,int] loot_maybe = buf.group_string("<td.+?You acquire an item: (.+)</td>");
	if (count(loot_maybe) > 0) {
		string prize = loot_maybe[0,1].group_string("<b>(.+)<font size=1")[0,1].group_string("(.+)</b>")[0,1];
		out.prize = to_item(prize);
	}

	if (debug) {
		print(stances.count()+" stances captured");
		print(out.rounds.count()+" rounds recorded");
		string attacker = fighters[0];
		string defender = fighters[1];
		print(`{attacker} attacks {defender}!`);
		foreach i,s in stances {
			if (!(stance_bimap contains s) && length(s) > 0) {
				buffer b = "unknown stance: [";
				for i from 0 to (length(s) - 1) {
					b.append(`'{s.char_at(i)}'`);
					if (i < length(s) - 1)
						b.append(", ");
				}
				print(b, "red");
			}
			if (out.rounds[s] == "D")
				print(`[{stance_bimap[s]}]: draw!`);
			else if (attacker_results[i].contains_text("youwin"))
				print(`[{stance_bimap[s]}]: {attacker} beat {defender} at {s}`);
			else
				print(`[{stance_bimap[s]}]: {defender} beat {attacker} at {s}`);
		}
		print("WINNER: " + (out.won() ? attacker : defender));
		if (out.prize != $item[none])
			print("Looted a " + out.prize);
	}

	return out;
}
fite examine_fite(int lid) {
	return examine_fite(lid, false);
}

//fite constructor, from fite.to_string()
fite from_string(string s, boolean debug) {
	string[int,int] groups = s.group_string("^(\\d+)([ad]) (\\w{14,}) (-?\\d+) (-?\\d+) (\\d+) (.*)$");
	fite out = new fite(
		groups[0,1].to_int(),	// opponent id
		groups[0,2] == "a",		// attacking?
		{},						// rounds
		to_int(groups[0,4]),	// fame
		to_int(groups[0,5]),	// stats
		to_int(groups[0,6]),	// swagger
		to_item(groups[0,7])	// [prize]
	);
	if (debug)
		foreach x,y,s in groups
			print(`{x},{y}: {s}`);
	foreach x,y,z in groups[0,3].group_string("([0-9A-Z])([WLD])")
		if (y == 0)
			out.rounds[stance_bimap[z.char_at(0)]] = z.char_at(1);
	return out;
}
fite from_string(string s) {
	return from_string(s, false);
}

int season_int() {
	static int season = 0;
	static {
		string page = visit_url("peevpee.php?place=rules", false).to_string();
		string season_str = page.xpath("//table//table//p[1]/text()")[0];
		matcher m = create_matcher("\(\\d+\)", season_str);
		if (m.find())
			season = m.group(1).to_int();
	}
	return season;
}

string[string] flags = {
	"backup"	: "copy cache to a backup",
	"help"		: "print these messages",
	"history"	: "adjust how many recent fights to calculate",
	"purge"		: "empty the cache",
	"recolor"	: "change colorblind modes"
};

void backup() {
	string file = "flogger." + season_int() + "." + my_name().to_lower_case();
	string[int] memory, backup;
	if (!file_to_map(file + ".txt", memory) || memory.count() == 0) {
		print("Nothing much to back up.", "red");
		return;
	}
	file_to_map(file + ".bak", backup);
	boolean created = (backup.count() == 0);
	foreach f in memory
		if (!(backup contains f))
			backup[f] = memory[f];
	if (memory.map_to_file(file + ".bak"))
		print("Cache copied to " + (created ? "new " : "") + "backup.");
	else
		abort("failed to save file" + file + ".bak");
}

void help() {
	foreach f in flags
		print("flogger " + f + " -- " + flags[f]);
}

void history() {
	cli_execute("flogger_freshness");
}

void purge() {
	string file = "flogger." + season_int() + "." + my_name().to_lower_case() + ".txt";
	string[int] memory;
	file_to_map(file, memory);
	foreach f in memory
		remove memory[f];
	if (memory.map_to_file(file))
		print("Purged.");
	else
		abort("failed to save file" + file);
}

void recolor() {
	string file = "flogger." + my_name().to_lower_case() + ".pref";
	string[string] memory;
	file_to_map(file, memory);
	switch (memory["colors"]) {
		case "nored"	: memory["colors"] = "nogreen";	break;
		case "nogreen"	: memory["colors"] = "noblue";	break;
		default			: memory["colors"] = "nored";
	}
	if (memory.map_to_file(file))
		print("Changed color mode.");
	else
		abort("failed to save file" + file);
}

void main(string args) {
	if (!(flags contains args.to_lower_case())) {
		print("flogger what?", "red");
		help();
	}
	else if ($strings[backup,purge] contains args.to_lower_case() && season_int() == 0)
		print("It's off-season.", "red");
	else
		call void args();
}
