string[string] flags = {
	"backup" 	: "copy cache to a backup",
	"purge"		: "empty the cache",
	"recolor"	: "change colorblind modes",
	"help"		: "print these messages"
};

				// one minified pvp fight
record fite {
	int A;		// 1: on attack
				// 0: on defense
	int[int] R;	// key: stance_to_int[{mini}]
				// value: 1: you won the mini
				//        0: you lost the mini
};

// an ugly, hacky, ash-doesn't-have-enums "enum"
// but it reduces cached file size by a bunch
int[string] stance_to_int;
string[int] int_to_stance;
foreach s in current_pvp_stances() {
	int_to_stance[int_to_stance.count()] = s;
	stance_to_int[s] = int_to_stance.count() - 1;
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
		out.R[stance_to_int[mini]] = (!(out.A.to_boolean() ^ results[i].contains_text('youwin'))).to_int();
	return out;
}

int season_int;

void backup() {
	boolean created;
	fite[int] working, backup;
	if (!file_to_map('flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt', working) || working.count() == 0) {
		print('Nothing much to back up.', 'red');
		return;
	}
	created = !file_to_map('flogger.'+season_int+'.'+my_name().to_lower_case()+'.bak', backup);
	foreach f in working
		if (!(backup contains f))
			backup[f] = working[f];
	if (working.map_to_file('flogger.'+season_int+'.'+my_name().to_lower_case()+'.bak'))
		print(`Cache copied to {created?'new ':''}backup.`);
	else
		abort('failed to save backup' + 'flogger.'+season_int+'.'+my_name().to_lower_case()+'.bak');
}

void purge() {
	fite[int] working;
	file_to_map('flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt', working);
	foreach f in working
		remove working[f];
	if (working.map_to_file('flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt'))
		print('Purged.');
	else
		abort('failed to purge' + 'flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt');
}

void recolor() {
	string[string] fmem;
	file_to_map('flogger.' + my_name().to_lower_case() + '.pref', fmem);
	switch (fmem['colors']) {
		case 'nored'	: fmem['colors'] = 'nogreen'; break;
		case 'nogreen'	: fmem['colors'] = 'noblue'; break;
		default			: fmem['colors'] = 'nored';
	}
	if (fmem.map_to_file('flogger.' + my_name().to_lower_case() + '.pref'))
		print('Changed color mode.');
	else
		abort('couldn\'t update file ' + 'flogger.' + my_name().to_lower_case() + '.pref');
}

void help() {
	foreach word in flags
		print(`{__FILE__.substring(0,__FILE__.length()-4)} {word} -- {flags[word]}`);
}

void main(string args) {
	if (args.split_string(' ').count() != 1 || !(flags contains args)) {
		print('flogger what?', 'red');
		help();
		return;
	}
	string page = visit_url('peevpee.php?place=rules',false).to_string();
	string season_str = page.xpath('//table//table//p[1]/text()')[0];
	matcher m = '\(\\d+\)'.create_matcher(season_str);
	if (!m.find()) {
		print('Is there even a pvp season right now? Chill.', 'red');
		return;
	}
	season_int = m.group(1).to_int();

	call void args();
}
