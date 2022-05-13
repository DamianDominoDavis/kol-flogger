// study, grasshopper
// learn over one thousand fights
// which kung fu is best

import <flogger.ash>

// select a color {x}% along the even linear gradient from A to Neutral to B
// return css-appropriate color value
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

string join(string sep, item[int] arr) {
	if (arr.count() < 1)
		return '';
	string o;
	foreach _,it in arr
		if (it.to_string().length() > 0)
			o += sep + it.to_string();
	return o.substring(sep.length());
}

// knockoff jquery
string append_child(string original, string tag_patten, string content) {
	matcher tag_matcher = tag_patten.create_matcher(original);
	if (tag_matcher.find())
		return original.replace_string(tag_matcher.group(1), tag_matcher.group(1) + content);
	abort("could not match tag_pattern => " + tag_patten);
	return "";
}

void main() {
	// override the rules
	// only when it's seasonal
	// and we've been fighting
	string page = visit_url().to_string();
	string[int] log = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1", false).xpath('//table//table//table//table//tr');
	if (form_field("place") != "rules" || season_int() == 0 || log.count() < 2) {
		page.write();
		return;
	}

	// load from memory
	// tally up wins and losses
	// save to file sometimes
	int gonna,fame,substats,swagger,flowers,winningness;
	item[int] prizes, expenses;
	boolean[int] got;
	int[string,boolean,boolean] scores;
	string file = "flogger." + season_int() + "." + my_name().to_lower_case() + ".txt";
	string[int] memory;
	file_to_map(file, memory);
	fite f;
	foreach i,s in log if (i!=0) {
		int L = s.group_string('lid=(\\d+)')[0,1].to_int();
		if (!(memory contains L))
			got[L] = true;
	}
	gonna = got.count();
	if (gonna > 0) {
		print('flogger caching '+gonna+' new recent fites...');
	}
	got = {};
	try {
		foreach i,s in log if (i!=0) {
			int L = s.group_string('lid=(\\d+)')[0,1].to_int();
			if (!(memory contains L)) {
				f = examine_fite(L);
				f.fame = s.group_string("([+-](\\d+).Fame)")[0,2].to_int();
				f.substats = s.group_string("([+-](\\d+).Stats)")[0,2].to_int();
				f.swagger = s.group_string("(\\\+(\\d+).Swagger)")[0,2].to_int();
				f.flowers = s.group_string("(\\+(\\d).Flower)")[0,2].to_int();
				memory[L] = f.to_string();
				got[L] = true;
			}
		}
		string[string] prefs;
		file_to_map("flogger." + my_name().to_lower_case() + ".pref", prefs);
		boolean extended = prefs["extended"].to_boolean();
		foreach L,s in memory if (extended || got[L]) {
			f = memory[L].from_string();
			if (f.fame != 0) {
				fame += f.fame;
				winningness += f.won()? 1 : -1;
			}
			substats += f.substats;
			swagger += f.swagger;
			flowers += f.flowers;
			foreach mini,winner in f.rounds
				scores[mini, f.attacking, winner]++;
			if (got.count() > 0 && got.count() % 50 == 0)
				map_to_file(memory, file);
		}
		
		
		if (extended) {
			foreach L,s in memory if (!(got contains L)) {
				got[L] = true;
				f = memory[L].from_string();
				foreach mini,winner in f.rounds
					scores[mini, f.attacking, winner]++;
			}
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
			"table table table tr td { white-space: normal; vertical-align: middle; padding: 0.5px 2px; } "+
			"table table table tr td:nth-child(n-3) { vertical-align: bottom; } "+
			"table table table td span { display:block; width:8em; border: 1px solid black; padding: 2px 0; font-weight: bold; color: white; text-shadow: 0px 0px 5px black;}"+
			"</style>"
		);
		string intro = page.split_string("<tr><th>Name</th>")[0];
		string[int] mid = page.xpath("//table//table//table//tr");
		string outro = "</table><p><small>" + page.split_string("</td></tr></table><p><small>")[1];
		intro.write();

		int attacks, defends;
		foreach mini,attacking,win in scores
			if (attacking)
				attacks += scores[mini,attacking,win];
			else
				defends += scores[mini,attacking,win];
		foreach i,s in mid {
			if (i == 0)
				s = s.append_child("<tr>(.+)</tr>", "<th>Attacking</th><th>Defending</th>");
			else foreach mini in current_pvp_stances() if (s.contains_text(mini) || s.contains_text(mini.replace_string("'",'&apos;')) || s.replace_string('rrr','r').contains_text(mini.replace_string('rrr','r'))) {
				float a,x;
				int b,c,y,z;
				if (scores[mini,true,true] + scores[mini,true,false] > 0) {
					b = scores[mini,true,true];
					c = scores[mini,true,false];
					a = (100.0 * b) / (b + c);
				}
				if (scores[mini,false,true] + scores[mini,false,false] > 0) {
					y = scores[mini,false,true];
					z = scores[mini,false,false];
					x = (100.0 * y) / (y + z);
				}
				s = s.append_child('<tr class="small">(.+)</tr>',
					`<td align="center" style="white-space: nowrap;">`+
						`{b}:{c} <strong>({attacks>0 ? ((100.0 * (b + c)) / attacks).to_string("%.1f") : '0'}%)</strong>`+
						`<span style="background-color:{colorize(a)};"}>{a.to_string("%.1f")}%</span>`+
					`</td>`+
					`<td align="center" style="white-space: nowrap;">`+
						`{y}:{z} <strong>({defends>0 ? ((100.0 * (y + z)) / defends).to_string("%.1f") : '0'}%)</strong>`+
						`<span style="background-color:{colorize(x)};"}>{x.to_string("%.1f")}%</span>`+
					`</td>`
				);
			}
			s.write();
		}
		sort prizes by -value.historical_price();
		sort expenses by -value.historical_price();
		int who,cares;
		foreach i,it in prizes
				who += i * it.historical_price();
		foreach i,it in expenses
				cares += i * it.historical_price();
		string footnote = "</small></p><p><small>** Attacking and defending win rates are over your " + (extended? memory.count()+" recent and cached": (got.count())+" most recent") + " fights.</small></p>"+
			`<p><small>Net: {fame.to_string('%+d')} fame, {swagger} swagger, {flowers} flowers, {winningness.to_string('%+d')} winningness, and -{substats} substats.</small></p>`;
		outro.append_child("<p>(.+)</p>", footnote).write();
	}
}
