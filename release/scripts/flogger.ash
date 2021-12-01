// one minified pvp fight
record fite {
	int A;			// value	1: on attack
					// 			0: on defense
	int[string] R;	// key: stance_to_int[{mini}]
					// value	1: you won the mini
					//        	0: you lost the mini
};

// an "enum" to minify stance strs and file sizes
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
	string[int] fighters = buf.xpath("//div[@class='fight']/a/text()");
	string[int] stances = buf.xpath("//tr[@class='mini']/td/center/b/text()");
	string[int] results = buf.xpath("//tr[@class='mini']/td[1]");
	out.A = (fighters[0].to_lower_case() == my_name().to_lower_case()).to_int();
	foreach i,mini in stances
		out.R[stance_to_char[mini]] = (!(out.A.to_boolean() ^ results[i].contains_text("youwin"))).to_int();
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
	fite[int] memory, backup;
	if (!file_to_map(file + ".txt", memory) || memory.count() == 0) {
		print("Nothing much to back up.", "red");
		return;
	}
	boolean created = !file_to_map(file + ".bak", backup);
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
	fite[int] memory;
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
	if ($strings[backup,purge] contains args && season_int() == 0)
		print("It's off-season.", "red");
	call void args();
}
