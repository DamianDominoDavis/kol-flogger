// study, grasshopper
// learn over one thousand fights
// which kung fu is best

import <flogger.ash>

// Xth value along
// gradient between two hues
// in the middle, grey
string colorize(int x) {
	string[string] fmem;
	string file = "flogger." + my_name().to_lower_case() + ".pref";
	file_to_map(file, fmem);
	if (fmem["colors"] == "nored")
		return `rgb({50-(x>50?x-50:50-x)}%, {x}%, {100-x}%)`;
	if (fmem["colors"] == "nogreen")
		return `rgb({100-x}%, {50-(x>50?x-50:50-x)}%, {x}%)`;
	return `rgb({100-x}%, {x}%, {50-(x>50?x-50:50-x)}%)`;
}

// python idiom
// stringify the list of things
// with separators
string join(string sep, item[int] arr) {
	if (arr.count() < 1)
		return '';
	string o;
	foreach _,it in arr
		if (it.to_string().length() > 0)
			o += sep + it.to_string();
	return o.substring(sep.length());
}

// knockoff jquery!
// have you ever seen something
// as degenerate
string append_child(string original, string tag_patten, string content) {
	matcher tag_matcher = tag_patten.create_matcher(original);
	if (tag_matcher.find())
		return original.replace_string(tag_matcher.group(1), tag_matcher.group(1) + content);
	abort("could not match tag_pattern => " + tag_patten);
	return "";
}

float out_of(float a,float b) {
	return (a+b==0)? 0 : (100.0 * a) / (a + b);
}

void main() {
	// override the rules
	// only when it's seasonal
	// and we've been fighting
	string page = visit_url("peevpee.php?place=rules").to_string();
	string[int] log = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1", false).xpath('//table//table//table//table//tr');
	if (season_int() == 0 || log.count() < 2) {
		page.write();
		return;
	}

	// enough is enough
	// compact mode can stay broken
	// til I feel like it
	int test_lid = log[1].group_string('lid=(\\d+)')[0,1].to_int();
	buffer test_fight = visit_url("peevpee.php?action=log&ff=1&lid="+test_lid+"&place=logs&pwd", false);
	if (test_fight.xpath("//div[@class='fight']").count() == 0) {
		string outro = "</table><p><small>" + page.split_string("</td></tr></table><p><small>")[1];
		string footnote = `</small></p><h1>Compact Mode for pvp breaks Flogger.</h1><h4>Go turn that off in your <a href="account.php">vanilla kol options</a>.</h4>`;
		outro.append_child("<p>(.+)</p>", footnote).write();
		page.write();
		return;
	}


	// load from memory
	// tally up wins and losses
	// save to file sometimes
	int gonna, got;
	string file = "flogger." + season_int() + "." + my_name().to_lower_case() + ".txt";
	string[int] memory;
	file_to_map(file, memory);
	foreach i,s in log if (i!=0) {
		int L = s.group_string('lid=(\\d+)')[0,1].to_int();
		if (!(memory contains L))
			gonna++;
	}
	if (gonna > 0) {
		print('flogger caching '+gonna+' new recent fites...');
	}

	int[string,boolean,boolean] scores;
	int[boolean,boolean] cumulative;
	int scanThisMany = 1000;

	try {
		fite f;
		int[int] to_score;
		foreach i,s in log if (i!=0) {
			int L = s.group_string('lid=(\\d+)')[0,1].to_int();
			to_score[to_score.count()] = L;
			if (!(memory contains L)) {
				f = examine_fite(L);
				f.fame = s.group_string("(([+-]\\d+).Fame)")[0,2].to_int();
				f.substats = s.group_string("(([+-]\\d+).Stats)")[0,2].to_int();
				f.swagger = s.group_string("(\\\+(\\d+).Swagger)")[0,2].to_int();
				f.flowers = s.group_string("(\\+(\\d).Flower)")[0,2].to_int();
				memory[L] = f.to_string();
			}
		}

		int fame,substats,swagger,flowers,winningness;
		string[string] prefs;
		file_to_map("flogger." + my_name().to_lower_case() + ".pref", prefs);
		scanThisMany = prefs["freshness"].to_int();
		if (scanThisMany < 1)
			scanThisMany = 1000;
		int skipThisMany = memory.count() - scanThisMany;
		foreach L in memory if (skipThisMany-- <= 0) {
			f = memory[L].from_string();
			cumulative[f.attacking,f.won()]++;
			if (f.fame != 0) {
				fame += f.fame;
				winningness += f.won()? 1 : -1;
			}
			substats += f.substats;
			swagger += f.swagger;
			flowers += f.flowers;
			foreach mini,winner in f.rounds
				scores[mini, f.attacking, winner]++;
			if (gonna > 0 && ++got % 50 == 0)
				map_to_file(memory, file);
		}
	}

	// save it all to file
	// render extra table cells
	// see what you have wrought
	finally {
		map_to_file(memory, file);
		if (gonna > 0)
			print('flogger done');
		page = page.append_child("<head>(.+)</head>",
			"<style>"+
			"table table table tr td { white-space: normal; vertical-align: middle!important; padding: 0.5px 2px; } "+
			"table table table tr td:nth-child(n-3) { vertical-align: bottom; } "+
			"table table table tr td:nth-child(n-3) { vertical-align: bottom; } "+
			"table table table td span { display:block; width:8em; border: 1px solid black; padding: 2px 0; font-weight: bold; color: white; text-shadow: 0px 0px 5px black;}"+
			"</style>"
		);

		page.split_string("<tr><th>Name</th>")[0].write();

		int total_attacks;
		int total_defends;
		foreach mini,attacking,win in scores {
			if (attacking)
				total_attacks += scores[mini,attacking,win];
			else
				total_defends += scores[mini,attacking,win];
		}
		foreach i,s in page.xpath("//table//table//table//tr") {
			if (i == 0)
				s = s.append_child("<tr>(.+)</tr>", "<th>Attacking</th><th>Defending</th>");
			else {
				string mini = int_to_stance[i-1];
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
				float favor_atk = (total_attacks <1) ? 0 : (100 * 10 / 6.0) * (to_float(atk_wins + atk_loss) / total_attacks - 1.0 / 12);
				float favor_def = (total_defends <1) ? 0 : (100 * 10 / 6.0) * (to_float(def_wins + def_loss) / total_defends - 1.0 / 12);
				//float rate_atk = (100) * (to_float(atk_wins + atk_loss) * 7.0 / total_attacks);
				//float rate_def = (100) * (to_float(def_wins + def_loss) * 7.0 / total_defends);
				s = s.append_child('<tr class="small">(.+)</tr>',
					`<td align="center" style="white-space: nowrap;">`+
						# 100 * (((atk_wins + atk_loss) * 7.0 / total_attacks - 7.0 / 12))
						`<small><strong>{total_attacks>0 ? favor_atk.to_string("%+.0f") : '0'} favor ({atk_wins}:{atk_loss})</strong></small>`+
						`<span style="background-color:{colorize(win_rate)};"}>{win_rate.to_string("%.1f")}%</span>`+
					`</td>`+
					`<td align="center" style="white-space: nowrap;">`+
						`<small><strong>{total_defends>0 ? favor_def.to_string("%+.0f") : '0'} favor ({def_wins}:{def_loss})</strong></small>`+
						`<span style="background-color:{colorize(loss_rate)};"}>{loss_rate.to_string("%.1f")}%</span>`+
					`</td>`);
			}
			s.write();
		}

		string outro = "</table><p><small>" + page.split_string("</td></tr></table><p><small>")[1];
		string footnote = "</small></p><p><small>** Favor measures how popular the mini-competitions are. Higher favor means chosen more often when attacking. </small></p>"
						+ "<p><small>*** Stats above are calculated over your last " + scanThisMany + " fights. Change this number with CLI command <code>flogger history</code>.</small></p>"
						+ `<p><small>You won {cumulative[true,true]} / {cumulative[true,true]+cumulative[true,false]} attacks ({cumulative[true,true].out_of(cumulative[true,false]).to_string('%.1f%%')}) `
						+ `and {cumulative[false,true]} / {cumulative[false,true]+cumulative[false,false]} defends ({cumulative[false,true].out_of(cumulative[false,false]).to_string('%.1f%%')}).</br>`
						+ `Net: {fame.to_string('%+d')} fame, {swagger} swagger, {flowers} flowers, {winningness.to_string('%+d')} winningness, and {substats} substats.</small></p>`;
		outro.append_child("<p>(.+)</p>", footnote).write();
	}
}
