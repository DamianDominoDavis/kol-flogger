record fite {
	boolean attacking;
	boolean[string] rounds;
	int fame;
	int substats;
	int swagger;
	int flowers;
	item prize;
};

boolean won(fite f) {
	int w;
	foreach mini,result in f.rounds
		w += (result? 1 : -1);
	return (w > 0);
}

// minified stance "enum"
static int[string] stance_to_int;
static string[int] int_to_stance;
int[string] from_hex = {'0':0,'1':1,'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8,'9':9,'A':10,'B':11};
if (stance_to_int.count() < 1) {
	buffer info = visit_url('peevpee.php?place=rules', false);
	foreach k,s in info.xpath('//table//table//table//tr//td[1]//text()') {
		string unstarred = (s.char_at(s.length()-1) =='*') ? s.substring(0, s.length()-1) : s;
		string unarrred = unstarred.replace_string('Rrr','R').replace_string('rrr','r');
		stance_to_int[unarrred] = k;
		int_to_stance[k] = unarrred;
	}
}
if (stance_to_int.count()!=12) abort('What are we fighting about?');
// else foreach i,s in int_to_stance print(`{i}: {s}`);

// fite constructor, takes uids from pvp log page links
fite examine_fite(int lid) {
	fite out;
	buffer buf = visit_url("peevpee.php?action=log&ff=1&lid="+lid+"&place=logs&pwd", false);
	string[int] fighters;
	string[int] stances;
	string[int] results;
	int debug_fite_id = -1;

	if (buf.xpath("//div[@class='fight']").count() > 0) { // expanded mode
		fighters = buf.xpath("//div[@class='fight']/a/text()");
		stances = buf.xpath("//tr[@class='mini']/td/center/b/text()");
		results = buf.xpath("//tr[@class='mini']/td[1]");
		foreach i in stances
			stances[i] = stances[i].replace_string('Rrr','R').replace_string('rrr','r');
		out.attacking = (my_name().to_lower_case() == fighters[0].to_lower_case());
		foreach i,mini in stances {
			out.rounds[mini] = (!(out.attacking ^ results[i].contains_text("youwin")));
		}
		if (lid == debug_fite_id) {
			print('attacking:' + out.attacking);
			print('Fighters:');
			foreach i,f in fighters print(`{i}: {f}`);
			print('stances:');
			foreach i,s in stances print(`{i}: {s}`);
			print('results:');
			foreach i,r in results print(`{i}: {r}`);
			print('out.rounds:');
			foreach s,b in out.rounds print(`{stance_to_int[s]}: {b}`);
		}
	}
	else abort("Turn off compact mode in your vanilla KOL options.");
	return out;
}

//fite constructor, from fite.to_string()
fite from_string(string s) {
	fite out;
	out.attacking = (s.char_at(0) == 'a');
	string tring = s.substring(1);
	string[int,int] groups = tring.group_string('([0-9AB][01])');
	foreach i in groups
		out.rounds[int_to_stance[from_hex[groups[i,0].char_at(0)]]] = (groups[i,0].char_at(1) == '1');
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
		out += stance_to_int[mini].to_string('%X') + (winner? '1' : '0');
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
