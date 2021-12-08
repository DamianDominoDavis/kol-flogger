record fite {
	boolean attacking;
	boolean[string] rounds;
};

// minified stance "enum"
string[string] stance_to_char;
string[string] char_to_stance;
foreach s in current_pvp_stances() {
	stance_to_char[s] = to_string(stance_to_char.count(), "%X");
	char_to_stance[stance_to_char[s]] = s;
}

// fite constructor, takes uids from pvp log page links
fite examine_fite(int lid) {
	fite out;
	buffer buf = visit_url("peevpee.php?action=log&ff=1&lid="+lid+"&place=logs&pwd", false);
	if (buf.xpath("//div[@class='fight']/a/text()").count() >= 2) {
		string[int] fighters = buf.xpath("//div[@class='fight']/a/text()");
		string[int] stances = buf.xpath("//tr[@class='mini']/td/center/b/text()");
		string[int] results = buf.xpath("//tr[@class='mini']/td[1]");
		out.attacking = (my_name().to_lower_case() == fighters[0].to_lower_case());
		foreach i,mini in stances
			out.rounds[mini] = (!(out.attacking ^ results[i].contains_text("youwin")));
	}
	else {
		string[int] fighters = buf.xpath("//table//table//table//table//tr//a/text()");	
		string[int] stances = buf.xpath("//table//table//table//table//tr/td[1]//b/text()");
		string[int] results = buf.xpath("//table//table//table//table//tr/td[2]//b/text()");
		out.attacking = (my_name().to_lower_case() == fighters[0].to_lower_case());
		foreach i,winner in results
			out.rounds[stances[i]] = (!(out.attacking ^ (my_name().to_lower_case() == results[i].to_lower_case())));
		}
	return out;
}

//fite constructor, from fite.to_string()
fite from_string(string s) {
	fite out;
	out.attacking = (s.char_at(0) == 'a');
	string[int,int] groups = s.group_string('([0-9A-F]{2})');
	foreach i in groups
		out.rounds[char_to_stance[groups[i,0].char_at(0)]] = (groups[i,0].char_at(1) == '1');
	return out;
}

string to_string(fite f) {
	string out = (f.attacking? 'a':'d');
	foreach mini,winner in f.rounds
		out += stance_to_char[mini] + (winner?'1':'0');
	return out;
}

int season_int() {
	static int season = 0;
	if (season == 0) {
		string page = visit_url("peevpee.php?place=rules", false).to_string();
		string season_str = page.xpath("//table//table//p[1]/text()")[0];
		matcher m = create_matcher("\(\\d+\)", season_str);
		if (!m.find())
			return 0;
		season = m.group(1).to_int();
	}
	return season;
}

string[string] flags = {
	"backup" 	: "copy cache to a backup",
	"purge"		: "empty the cache",
	"recolor"	: "change colorblind modes",
	"help"		: "print these messages"
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

void help() {
	foreach f in flags
		print("flogger " + f + " -- " + flags[f]);
}

void main(string args) {
	if (args.split_string(' ').count() != 1 || !(flags contains args.to_lower_case())) {
		print('flogger what?', 'red');
		help();
		return;
	}
	if ($strings[backup,purge] contains args.to_lower_case() && season_int() == 0)
		print("It's off-season.", "red");
	call void args();
}
