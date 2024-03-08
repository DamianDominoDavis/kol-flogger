record fite {
	boolean attacking;
	string[string] rounds;
	int fame;
	int substats;
	int swagger;
	int flowers;
	item prize;
};

string stance_name(string s) {
	static string[string] cache;
	if (!(cache contains s)) {
		string stripped = (s.length() > 1 &&  s.char_at(s.length()-1) =='*') ? s.substring(0, s.length()-1) : s;
		if (!($strings[Purrrity,Thirrrsty forrr Booze] contains s))
			stripped = stripped.replace_string('Rrr','R').replace_string('rrr','r');
		stripped = stripped.replace_string('†','').replace_string('&#8224;','').replace_string('&dagger;','');
		stripped = stripped.replace_string('‡','').replace_string('&#8225;','').replace_string('&Dagger;','');
		stripped = stripped.replace_string('&apos;',"'").replace_string('&#39;',"'");
		cache[s] = stripped;
	}
	return cache[s];
}

// minified stance "enum"
static string[string] stance_bimap;
if (stance_bimap.count() < 1) {
	buffer info = visit_url('peevpee.php?place=rules', false);
	foreach k,s in info.xpath('//table//table//table//tr/td[1]/b/text()') {
		stance_bimap[k.to_string("%X")] = stance_name(s);
		stance_bimap[stance_name(s)] = k.to_string("%X");
	}
	if (stance_bimap.count() < 2*12) {
		int k = stance_bimap.count() - stance_bimap.count() / 2;
		stance_bimap[k.to_string("%X")] = "[ tiebreaker ]";
		stance_bimap["[ tiebreaker ]"] = k.to_string("%X");
	}
}
// foreach i,s in stance_bimap print(`{i}: {s}`);
// if (stance_bimap.count()!=24) abort('What are we fighting about?');

string win_lose_draw(boolean attacking, boolean attacker_win, boolean defender_win) {
	if (attacker_win && defender_win)
		abort("double wins are draws? something is wrong");
	if ((attacking && attacker_win) || (!attacking && defender_win))
		return('W');
	if ((attacking && defender_win) || (!attacking && attacker_win))
		return('L');
	if (!attacker_win && !defender_win)
		return('D');
	abort ("who won? who\'s next? you decide.");
	return "X";
}

boolean won(fite f) {
	int w,l,d;
	foreach mini,result in f.rounds
		switch(result) {
			case ("W"): w++; break;
			case ("L"): l++; break;
			case ("D"): d++; break;
			default: abort("what hap");
		}
	return f.attacking ? w > l : w >= l;
}

boolean flawless(fite f) {
	if (!f.attacking)
		return false;
	int w,l,d;
	foreach mini,result in f.rounds
		switch(result) {
			case ("W"): w++; break;
			case ("L"): l++; break;
			case ("D"): d++; break;
			default: abort("what hap");
		}
	return (w == 7);
}

// fite constructor, takes uids from pvp log page links
fite examine_fite(int lid) {
	fite out;
	buffer buf = visit_url("peevpee.php?action=log&ff=1&lid="+lid+"&place=logs&pwd", false);
	string[int] fighters;
	string[int] stances;
	string[int] attacker_results;
	string[int] defender_results;
	int debug_fite_id = 77871;

	if (buf.xpath("//div[@class='fight']").count() <= 0) // require expanded mode
		abort("Turn off compact mode in your vanilla KOL options.");

	fighters = buf.xpath("//div[@class='fight']/a/text()");
	stances = buf.xpath("//tr[@class='mini']/td/center");
	attacker_results = buf.xpath("//tr[@class='mini']/td[1]");
	defender_results = buf.xpath("//tr[@class='mini']/td[3]");
	foreach i in stances {
		stances[i] = stances[i].xpath("//b/text()")[0].stance_name();
		if (stances[i] == "")
			stances[i] = "[ tiebreaker ]";
	}
	out.attacking = (my_name().to_lower_case() == fighters[0].to_lower_case());
	foreach i,mini in stances
		out.rounds[mini] = win_lose_draw(out.attacking, attacker_results[i].contains_text("youwin"), defender_results[i].contains_text("youwin"));

	if (lid == debug_fite_id) {
		print('attacking:' + out.attacking);
		print('Fighters:');
		foreach i,f in fighters
			print(`{i}: {f}`);
		print('stances:');
		foreach i,s in stances
			print(`{i}: {s} {attacker_results[i].contains_text("youwin")} {defender_results[i].contains_text("youwin")}`);
		print('out.rounds:');
		foreach s,b in out.rounds
			print(`{s}: {b}`);
		print('I AM WINNER: ' + (out.won()));
	}
	return out;
}

//fite constructor, from fite.to_string()
fite from_string(string s) {
	fite out;
	out.attacking = (s.char_at(0) == 'a');
	string tring = s.substring(1);
	string[int,int] groups = tring.group_string('([0-9ABC][WLD])');
	foreach i in groups
		out.rounds[stance_bimap[groups[i,0].char_at(0)]] = groups[i,0].char_at(1);
	string[int] rest = tring.split_string(' ');
	out.fame = rest[1].to_int();
	out.substats = rest[2].to_int();
	out.swagger = rest[3].to_int();
	out.flowers = rest[4].to_int(); 
//	out.prize = rest[5].to_item();
	return out;
}

string to_string(fite f) {
	string out = (f.attacking? 'a':'d');
	foreach mini,winner in f.rounds
		out += stance_bimap[mini] + winner;
	return out + ` {f.fame} {f.substats} {f.swagger} {f.flowers}`; // {f.prize}
}

int season_int() {
	static int season = 0;
	if (season == 0) {
		string page = visit_url("peevpee.php?place=rules", false).to_string();
		string season_str = page.xpath("//table//table//p[1]/text()")[0];
		matcher m = create_matcher("\(\\d+\)", season_str);
		if (m.find())
			season = m.group(1).to_int();
	}
	return season;
}

string[string] flags = {
	"backup" 	: "copy cache to a backup",
	"help"		: "print these messages",
	"history"	: "toggle calculating only the last 1000 fites / all cached fites",
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
	cli_execute('flogger_freshness');
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
		print('flogger what?', 'red');
		help();
		return;
	}
	if ($strings[backup,purge] contains args.to_lower_case() && season_int() == 0)
		print("It's off-season.", "red");
	call void args();
}
