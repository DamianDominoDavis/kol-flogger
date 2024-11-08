// study, grasshopper
// learn over one thousand fights
// which kung fu is best
import <flogger.ash>

// gradient from A to gray to B
string colorize(int x) {
	switch (get_pref("colors")) {
		case "nored": return `rgb({50-(x>50?x-50:50-x)}%, {x}%, {100-x}%)`;
		case "nogreen": return `rgb({100-x}%, {50-(x>50?x-50:50-x)}%, {x}%)`;
		case "noblue": return `rgb({100-x}%, {x}%, {50-(x>50?x-50:50-x)}%)`;
		default: return `rgb({x}%, {x}%, {x}%)`;
	}
}

// append text to the first capture of some regex, must capture
string append_child(string original, string tag_patten, string content) {
	matcher tag_matcher = tag_patten.create_matcher(original);
	if (tag_matcher.find())
		return original.replace_string(tag_matcher.group(1), tag_matcher.group(1) + content);
	abort("could not match tag_pattern => " + tag_patten);
	return "";
}

// fractions
float out_of(float a,float b) {
	return (a+b==0)? 0 : (100.0 * a) / (a + b);
}

// counting the days
int dateDifference(string d1, string d2) {
	static int[int] daysUpToMonth = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };
	static int[int] daysUpToMonthLeapYear = { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 };
	int daysOffsetFromOrigin(string d) {
		string[int] groops = d.split_string("-");
		int year = groops[0].to_int();
		int month = groops[1].to_int();
		int day = groops[2].to_int();
		year--;
		int numOfLeapsYear = year / 4 - year / 100 + year / 400;
		if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))
			return year * 365 + numOfLeapsYear + daysUpToMonthLeapYear[month - 1] + day - 1;
		else
			return year * 365 + numOfLeapsYear + daysUpToMonth[month - 1] + day - 1;
	}
	int daysOffset = daysOffsetFromOrigin(d1);
	int daysOffset2 = daysOffsetFromOrigin(d2);
	return (daysOffset2 - daysOffset);
}

void main() {
	string page = visit_url("peevpee.php?place=rules").to_string();
	string[int] log = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1", false).xpath('//table//table//table//table//tr');
	int[string,boolean,boolean] scores;
	int[boolean,boolean] cumulative;
	int perfect;
	int freshness;
	int gonna;
	int got;
	string colors;
	string[int] memory;
	file_to_map(cache_file, memory);

	// return the unmodified info booth if we have no stats to display
	if (season_int() == 0 || log.count() < 2) {
		page.write();
		return;
	}

	// require expanded fights
	int test_lid = log[1].group_string('lid=(\\d+)')[0,1].to_int();
	buffer test_fight = visit_url("peevpee.php?action=log&ff=1&lid="+test_lid+"&place=logs&pwd", false);
	if (test_fight.xpath("//div[@class='fight']").count() == 0) {
		string outro = "</table><p><small>" + page.split_string("</td></tr></table><p><small>")[1];
		string footnote = `</small></p><h1>Compact Mode for pvp breaks Flogger.</h1><h4>Go turn that off in your <a href="account.php">vanilla kol options</a>.</h4>`;
		outro.append_child("<p>(.+)</p>", footnote).write();
		page.write();
		return;
	}

	// emit new fights count
	foreach i,s in log if (i!=0) {
		int L = s.group_string('lid=(\\d+)')[0,1].to_int();
		if (!(memory contains L))
			gonna++;
	}
	if (gonna > 0)
		print('flogger caching '+gonna+' new recent fites...');

	try {
		// cache new fights
		fite f;
		foreach i,s in log if (i!=0) {
			int L = s.group_string('lid=(\\d+)')[0,1].to_int();
			if (!(memory contains L)) {
				f = examine_fite(L);
				f.fame = s.group_string("(([+-]\\d+).Fame)")[0,2].to_int();
				f.substats = s.group_string("(([+-]\\d+).Stats)")[0,2].to_int();
				f.swagger = s.group_string("(\\\+(\\d+).Swagger)")[0,2].to_int();
				memory[L] = f.as_string();
				if (++got % 10 == 0)
					map_to_file(memory, cache_file);
			}
		}

		// check prefs
		freshness = to_int((form_fields() contains "freshness"? form_fields() : all_prefs())["freshness"]);
		if (freshness < 1)
			freshness = 1000;
		set_pref("freshness", to_string(freshness));
		colors = form_fields() contains "colors"? form_fields()["colors"] : get_pref("colors");
		if (colors == "")
			colors = "nogreen";
		set_pref("colors", colors);

		// aggregate scores, emit debug fights
		int fame;
		int substats;
		int swagger;
		int winningness;
		int skipThisMany = memory.count() - freshness;
		foreach L in memory if (debug_fite_ids contains L || skipThisMany-- <= 0) {
			if (debug_fite_ids contains L)
				examine_fite(L, true);
			f = memory[L].from_string(debug_fite_ids contains L);
			cumulative[f.attacking,f.won()]++;
			fame += f.fame;
			winningness += to_int(f.attacking) * (f.won() ? 1 : -1);
			substats += f.substats;
			swagger += f.swagger;
			perfect += to_int(f.flawless());
			foreach mini,winner in f.rounds
				scores[mini, f.attacking, winner=='W']++;
		}
		if (got > 0)
			print('flogger done');
	}

	finally {
		map_to_file(memory, cache_file);
		int total_attacks;
		int total_defends;
		foreach mini,attacking,win in scores {
			if (attacking)
				total_attacks += scores[mini,attacking,win];
			else
				total_defends += scores[mini,attacking,win];
		}

		// page top
		page = page.append_child("<head>(.+)</head>",
			"<style>"+
			"table table table tr td { white-space: normal; vertical-align: middle!important; padding: 0.5px 2px; } "+
			"table table table tr td:nth-child(n-3) { vertical-align: bottom; } "+
			"table table table tr td:nth-child(n-3) { vertical-align: bottom; } "+
			"table table table td span { display:block; width:8em; border: 1px solid black; padding: 2px 0; font-weight: bold; color: white; text-shadow: 0px 0px 5px black;}"+
			"</style>"
		);
		string[int] bookends = {"<p><b>Current Season: </b>"+season_int()+"<br />", "<p><b>Active Mini Competitions:"};
		string header = page.split_string(bookends[0])[0];
		header = header.replace_string("Information Booth", "Flogger");
		header.write();
		string intro = page.xpath("//table//table//p[2]")[0];
		string[int,int] dates = intro.group_string("\\d{4}-\\d*-\\d*");
		string fmt = "yyyy-MM-dd";
		string today_date = now_to_string(fmt);
		string freeze_date = dates[1,0];
		string end_date = dates[0,0];
		int til_freeze = dateDifference(today_date, freeze_date);
		int til_end = dateDifference(today_date, end_date);
		intro = get_property("currentPVPSeason");
		intro = intro.char_at(0).to_upper_case() + intro.substring(1);
		intro = `<center><p>Season {season_int()}: <b>{intro} Season</b>! `
			+ (til_freeze > 0 ? `Leaderboards freeze in <b>{til_freeze}</b> days. ` : "")
			+ `Season ends in <b>{til_end}</b> days. `
			+ `<b>Happy hunting!</b><br /></p></center><p><table>`;
		intro.write();

		// table rows
		foreach i,tr in page.xpath("//table//table//table//tr") {
			if (i == 0)
				tr = tr.append_child("<tr>(.+)</tr>", "<th>Attacking</th><th>Defending</th>");
			else {
				string mini = tr.xpath("//b/text()")[0].stance_name();
				int atk_wins;
				int atk_loss;
				int def_wins;
				int def_loss;
				float win_rate;
				float loss_rate;
				if (scores[mini,true,true] + scores[mini,true,false] > 0) {
					atk_wins = scores[mini,true,true];
					atk_loss = scores[mini,true,false];
					win_rate = out_of(atk_wins, atk_loss);
				}
				if (scores[mini,false,true] + scores[mini,false,false] > 0) {
					def_wins = scores[mini,false,true];
					def_loss = scores[mini,false,false];
					loss_rate = out_of(def_wins, def_loss);
				}
				//float rate_atk = (100) * (to_float(atk_wins + atk_loss) * 7.0 / total_attacks);
				//normalized to ±10
				float favor_atk = (total_attacks <1) ? 0 : (100 * 10 / 6.0) * (to_float(atk_wins + atk_loss) / total_attacks - 1.0 / 12);
				float favor_def = (total_defends <1) ? 0 : (100 * 10 / 6.0) * (to_float(def_wins + def_loss) / total_defends - 1.0 / 12);
				tr = tr.append_child('<tr class="small">\(.+\)</tr>',
					`<td align="center" style="white-space: nowrap;">`+
						`<small><strong>{total_attacks>0 ? favor_atk.to_string("%+.0f") : '0'} favor ({atk_wins}:{atk_loss})</strong></small>`+
						`<span style="background-color:{colorize(win_rate)};"}>{win_rate.to_string("%.1f")}%</span>`+
					`</td>`+
					`<td align="center" style="white-space: nowrap;">`+
						`<small><strong>{total_defends>0 ? favor_def.to_string("%+.0f") : '0'} favor ({def_wins}:{def_loss})</strong></small>`+
						`<span style="background-color:{colorize(loss_rate)};"}>{loss_rate.to_string("%.1f")}%</span>`+
					`</td>`);
			}
			tr.write();
		}
		float[int] overall = {
			out_of(cumulative[true,true], cumulative[true,false]),
			out_of(cumulative[false,true], cumulative[false,false])
		};
		write(`<tr class="small"><td colspan="" align="center" valign="top" nowrap="nowrap"><p><b><big><big>Overall</big></big></b></td><td></td><td></td><td></td>`
				+ `<td align="center" style="white-space: nowrap;"><big><strong>{cumulative[true,true]}:{cumulative[true,false]}</strong></big><span style="background-color:{colorize(overall[0])};"}><big>{overall[0].to_string("%.1f")}%</big></span></td>`
				+ `<td align="center" style="white-space: nowrap;"><big><strong>{cumulative[false,true]}:{cumulative[false,false]}</strong></big><span style="background-color:{colorize(overall[1])};"}><big>{overall[1].to_string("%.1f")}%</big></span></td>`
			+ `</tr>`
		);

		// page bottom
		string make_option(string value, string label) {
			return '<option value="' + value + '"' + (colors == value ? 'selected="true"' : '') + '>' + label + '</option>';
		}
		string outro = `</tr></table><center><p><small>Net: {fame.to_string('%+d')} fame, {swagger} swagger ({perfect} from flawless victory), {winningness.to_string('%+d')} winningness, and {substats} substats</small></p>`
			+ `<form>Score <input type="text" id="freshness" name="freshness" value="{freshness}" size="5" maxlength="4" /> <label for="freshness"> latest fights.</label><br />`
			+ `Show <select name="colors" id="colors">`
				+ make_option("noblue", "green/red")
				+ make_option("nored", "green/blue")
				+ make_option("nogreen", "blue/red")
			+ `</select> <label for="colors">colors.</label><br />`
			+ `<button type="submit">Reload</button></form>`
			+ `<p><a href="peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1">Archives</a> &mdash; <a href="peevpee.php">Back to The Colosseum</a><br /></p></center>`
			+ "</td></tr></table></td></tr></table></center></body></html>";
		outro.write();
	}
}
