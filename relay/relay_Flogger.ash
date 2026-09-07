// study, grasshopper
// learn over one thousand fights
// which kung fu is best
import flogger

record flogger_prefs {
	int freshness;
	string colors;
};

record scoreboard {
	int[string,boolean,boolean] scores;
	int[boolean,boolean] cumulative;
	int fame;
	int substats;
	int swagger;
	int winningness;
	int perfect;
	int total_attacks;
	int total_defends;
};

// gradient from A to gray to B
string colorize(int x, string colors) {
	switch (colors) {
		case "nored": return `rgb({50-(x>50?x-50:50-x)}%, {x}%, {100-x}%)`;
		case "nogreen": return `rgb({100-x}%, {50-(x>50?x-50:50-x)}%, {x}%)`;
		case "noblue": return `rgb({100-x}%, {x}%, {50-(x>50?x-50:50-x)}%)`;
		default: return `rgb({x}%, {x}%, {x}%)`;
	}
}

// append text to the first capture of some regex, must capture
string append_child(string original, string tag_pattern, string content) {
	matcher tag_matcher = tag_pattern.create_matcher(original);
	if (tag_matcher.find())
		return original.replace_string(tag_matcher.group(1), tag_matcher.group(1) + content);
	abort("could not match tag_pattern => " + tag_pattern);
	return "";
}

// fractions
float out_of(float a, float b) {
	return (a + b == 0) ? 0 : (100.0 * a) / (a + b);
}

// counting the days
int days_between(string d1, string d2) {
	int days_since_jan1(int m, boolean leapyear) {
		return int[int] { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 }[m] + to_int(leapyear && m > 1);
	}
	int days_since_year1(string d) {
		string[int] groops = d.split_string("-");
		int year = groops[0].to_int() - 1;
		int month = groops[1].to_int() - 1;
		int day = groops[2].to_int() - 1;
		int leap_days = year / 4 - year / 100 + year / 400;
		boolean leap_this_year = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
		return year * 365 + leap_days + days_since_jan1(month, leap_this_year) + day;
	}
	return days_since_year1(d2) - days_since_year1(d1) - 1;
}

boolean drunken_season() {
	return get_property("currentPVPSeason") == "drunken";
}

int lid_of(string row) {
	return row.group_string('lid=(\\d+)')[0,1].to_int();
}

// fame / stats / swagger live on the archive row, not the fight log
fite with_archive_stats(fite f, string row) {
	f.fame = row.group_string("(([+-]\\d+).Fame)")[0,2].to_int();
	f.substats = row.group_string("(([+-]\\d+).Stats)")[0,2].to_int();
	f.swagger = row.group_string("(\\\+(\\d+).Swagger)")[0,2].to_int();
	return f;
}

flogger_prefs read_prefs() {
	string[string] fields = form_fields();
	flogger_prefs out;
	out.freshness = to_int((fields contains "freshness" ? fields : all_prefs())["freshness"]);
	if (out.freshness < 1)
		out.freshness = 1000;
	set_pref("freshness", to_string(out.freshness));
	out.colors = fields contains "colors" ? fields["colors"] : get_pref("colors");
	if (out.colors == "")
		out.colors = "nogreen";
	set_pref("colors", out.colors);
	return out;
}

string[int] load_fight_log() {
	return visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1", false).xpath('//table//table//table//table//tr');
}

boolean compact_mode(string[int] log) {
	buffer test_fight = visit_url("peevpee.php?action=log&ff=1&lid="+lid_of(log[1])+"&place=logs&pwd", false);
	return test_fight.xpath("//div[@class='fight']").count() == 0;
}

void write_compact_warning(string page) {
	string outro = "</table><p><small>" + page.split_string("</td></tr></table><p><small>")[1];
	string footnote = `</small></p><h1>Compact Mode for pvp breaks Flogger.</h1><h4>Go turn that off in your <a href="account.php">vanilla kol options</a>.</h4>`;
	outro.append_child("<p>(.+)</p>", footnote).write();
	page.write();
}

void announce_uncached(string[int] log, string[int] memory) {
	int gonna;
	foreach i,s in log if (i != 0)
		if (!(memory contains lid_of(s)))
			gonna++;
	if (gonna > 0)
		print('flogger caching '+gonna+' new recent fites...');
}

void cache_new_fites(string[int] log, string[int] memory) {
	int got;
	foreach i,s in log if (i != 0) {
		int L = lid_of(s);
		if (!(memory contains L)) {
			memory[L] = examine_fite(L).with_archive_stats(s).as_string();
			if (++got % 10 == 0)
				map_to_file(memory, cache_file);
		}
	}
	if (got > 0)
		print('flogger done');
}

scoreboard with_totals(scoreboard board) {
	foreach mini,attacking,win in board.scores {
		if (attacking)
			board.total_attacks += board.scores[mini,attacking,win];
		else
			board.total_defends += board.scores[mini,attacking,win];
	}
	return board;
}

scoreboard score_memory(string[int] memory, int freshness) {
	scoreboard board;
	int skipThisMany = memory.count() - freshness;
	foreach L in memory if (debug_fite_ids contains L || skipThisMany-- <= 0) {
		if (debug_fite_ids contains L)
			examine_fite(L, true);
		fite f = memory[L].from_string(debug_fite_ids contains L);
		board.cumulative[f.attacking, f.won()]++;
		board.fame += f.fame;
		board.winningness += to_int(f.attacking) * (f.won() ? 1 : -1);
		board.substats += f.substats;
		board.swagger += f.swagger;
		board.perfect += to_int(f.flawless());
		foreach mini,winner in f.rounds
			board.scores[mini, f.attacking, winner=='W']++;
	}
	return board.with_totals();
}

string page_css() {
	return "<style>"+
		"table table table tr td { white-space: normal; vertical-align: middle!important; padding: 0.5px 2px; } "+
		"table table table tr td:nth-child(n-3) { vertical-align: bottom; } "+
		"table table table td span { display:block; width:8em; border: 1px solid black; padding: 2px 0; font-weight: bold; color: white; text-shadow: 0px 0px 5px black;}"+
		"</style>";
}

void write_header(string page) {
	string header = page.append_child("<head>(.+)</head>", page_css());
	header = header.split_string("<p><b>Current Season: </b>"+season_int())[0];
	header.replace_string("Information Booth", "Flogger").write();
}

string season_intro(string page) {
	string[int] intro_group = drunken_season()
		? page.xpath("//table//table//table//p")
		: page.xpath("//table//table//p[2]");
	string intro;
	if (count(intro_group) > 0)
		intro = intro_group[0];
	string[int,int] dates = intro.group_string("\\d{4}-\\d*-\\d*");
	string today = now_to_string("yyyy-MM-dd");
	int til_freeze = days_between(today, dates[1,0]);
	int til_end = days_between(today, dates[0,0]);
	string theme = get_property("currentPVPSeason");
	theme = theme.char_at(0).to_upper_case() + theme.substring(1);
	return `<center><p>Season {season_int()}: <b>{theme} Season</b>! `
		+ (til_freeze > 0 ? `Leaderboards freeze in <b>{til_freeze}</b> days. ` : "")
		+ `Season ends in <b>{til_end}</b> days. `
		+ `<b>Happy hunting!</b><br /></p></center><p><table style="display: inline;">`;
}

// normalized to ±10
float favor_score(int wins, int losses, int total) {
	return (total < 1) ? 0 : (100 * 10 / 6.0) * (to_float(wins + losses) / total - 1.0 / 12);
}

string favor_cell(int wins, int losses, int total, float rate, string colors) {
	string shown = total > 0 ? favor_score(wins, losses, total).to_string("%+.0f") : "0";
	return `<td align="center" style="white-space: nowrap;">`+
		`<small><strong>{shown} favor ({wins}:{losses})</strong></small>`+
		`<span style="background-color:{colorize(rate, colors)};">{rate.to_string("%.1f")}%</span>`+
		`</td>`;
}

string overall_cell(int wins, int losses, float rate, string colors) {
	return `<td align="center" style="white-space: nowrap;">`+
		`<big><strong>{wins}:{losses}</strong></big>`+
		`<span style="background-color:{colorize(rate, colors)};"><big>{rate.to_string("%.1f")}%</big></span>`+
		`</td>`;
}

string mini_cells(string mini, scoreboard board, string colors) {
	int atk_wins;
	int atk_loss;
	int def_wins;
	int def_loss;
	float win_rate;
	float loss_rate;
	if (board.scores[mini,true,true] + board.scores[mini,true,false] > 0) {
		atk_wins = board.scores[mini,true,true];
		atk_loss = board.scores[mini,true,false];
		win_rate = out_of(atk_wins, atk_loss);
	}
	if (board.scores[mini,false,true] + board.scores[mini,false,false] > 0) {
		def_wins = board.scores[mini,false,true];
		def_loss = board.scores[mini,false,false];
		loss_rate = out_of(def_wins, def_loss);
	}
	return favor_cell(atk_wins, atk_loss, board.total_attacks, win_rate, colors)
		+ favor_cell(def_wins, def_loss, board.total_defends, loss_rate, colors);
}

string[int] mini_rows(string page) {
	return drunken_season()
		? page.xpath("//table//table//table[2]//tr")
		: page.xpath("//table//table//table//tr");
}

void write_mini_table(string page, scoreboard board, string colors) {
	foreach i,tr in mini_rows(page) {
		if (i == 0)
			tr = tr.append_child("<tr>(.+)</tr>", "<th>Attacking</th><th>Defending</th>");
		else
			tr = tr.append_child('<tr class="small">\(.+\)</tr>', mini_cells(tr.xpath("//b/text()")[0].stance_name(), board, colors));
		tr.write();
	}
}

string overall_row(scoreboard board, string colors) {
	float atk_rate = out_of(board.cumulative[true,true], board.cumulative[true,false]);
	float def_rate = out_of(board.cumulative[false,true], board.cumulative[false,false]);
	return `<tr class="small">`
		+ `<td align="center" valign="top" nowrap="nowrap">`
		+ 	`<p><b><big><big>Overall</big></big></b></td>`
		+ `<td></td><td></td><td></td>`
		+ overall_cell(board.cumulative[true,true], board.cumulative[true,false], atk_rate, colors)
		+ overall_cell(board.cumulative[false,true], board.cumulative[false,false], def_rate, colors)
		+ `</tr>`;
}

string footer_stats(scoreboard board) {
	int attacks_won = board.cumulative[true,true];
	float fights = attacks_won + board.cumulative[true,false];
	string outro = `</tr></table><center><p>`;
	if (attacks_won > 0)
		outro += `<small>Average Win: {(board.fame.to_float()/attacks_won).to_string('%+.1f')} fame, {(board.swagger.to_float()/attacks_won).to_string("%.1f")} swagger (including a {(board.perfect * 100.0 / attacks_won).to_string("%.1f")}% chance of flawless victory)</small><br />`;
	if (fights > 0)
		outro += `<span><small>Net: {board.fame.to_string('%+d')} fame, {board.swagger} swagger ({board.perfect} from flawless victory), {board.winningness.to_string('%+d')} winningness, and {board.substats} substats</small>`;
	return outro;
}

string color_option(string value, string label, string colors) {
	return '<option value="' + value + '"' + (colors == value ? 'selected="true"' : '') + '>' + label + '</option>';
}

string prefs_form(flogger_prefs prefs) {
	return `</p><form>Score `
		+ `<input type="text" id="freshness" name="freshness" value="{prefs.freshness}" size="5" maxlength="4" /> `
		+ `<label for="freshness"> latest fights.</label><br />`
		+ `Show <select name="colors" id="colors">`
			+ color_option("noblue", "green/red", prefs.colors)
			+ color_option("nored", "green/blue", prefs.colors)
			+ color_option("nogreen", "blue/red", prefs.colors)
			+ color_option("blackwhite", "white/black", prefs.colors)
		+ `</select>`
		+ `<label for="colors"> colors.</label><br />`
		+ `<button type="submit">Reload</button>`
		+ `</form>`;
}

string nav_links() {
	return `<a href="peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1">Archives</a> &mdash; <a href="peevpee.php">Back to The Colosseum</a></span></center>`
		+ "</td></tr></table></td></tr></table></span></center></body></html>";
}

string page_foot(scoreboard board, flogger_prefs prefs) {
	return footer_stats(board) + prefs_form(prefs) + nav_links();
}

void render_flogger(string page, scoreboard board, flogger_prefs prefs) {
	write_header(page);
	season_intro(page).write();
	write_mini_table(page, board, prefs.colors);
	overall_row(board, prefs.colors).write();
	page_foot(board, prefs).write();
}

void main() {
	string page = visit_url("peevpee.php?place=rules").to_string();
	string[int] log = load_fight_log();

	if (season_int() == 0 || log.count() < 2) {
		page.write();
		return;
	}
	if (compact_mode(log)) {
		write_compact_warning(page);
		return;
	}

	string[int] memory;
	file_to_map(cache_file, memory);
	announce_uncached(log, memory);

	flogger_prefs prefs;
	scoreboard board;
	try {
		cache_new_fites(log, memory);
		prefs = read_prefs();
		board = score_memory(memory, prefs.freshness);
	} finally {
		map_to_file(memory, cache_file);
		render_flogger(page, board, prefs);
	}
}
