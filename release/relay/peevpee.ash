// study, grasshopper
// learn over one thousand fights
// which kung fu is best

import <flogger.ash>

// select a color {x}% along the even linear gradient from A to Neutral to B
// return css-appropriate color value
string colorize(int x) {
	string[string] fmem;
	file_to_map('flogger.'+my_name().to_lower_case()+'.pref', fmem);
	if (fmem['colors'] == 'nored')
		return `rgb({50-(x>50?x-50:50-x)}%,{x}%,{100-x}%)`;
	if (fmem['colors'] == 'nogreen')
		return `rgb({100-x}%,{50-(x>50?x-50:50-x)}%,{x}%)`;
	return `rgb({100-x}%,{x}%,{50-(x>50?x-50:50-x)}%)`;
}

// like jquery, but gross
// tag_pattern takes exactly one capture group
string append_child(string original, string tag_patten, string content) {
	matcher tag_matcher = tag_patten.create_matcher(original);
	if (tag_matcher.find())
		return original.replace_string(tag_matcher.group(1), tag_matcher.group(1) + content);
	abort("could not match tag_pattern => " + tag_patten);
	return '';
}

void main() {
	// override only at the rules page, when a season is on, and if we have participated
	string page = visit_url().to_string();
	int season_int;
	string season_str = page.xpath('//table//table//p[1]/text()')[0];
	matcher m = '\(\\d+\)'.create_matcher(season_str);
	string[int,int] log = visit_url('peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1', false).group_string("action=log&ff=1&lid=\(\\d\+\)&place=logs");
	if (form_field('place') != 'rules' || !m.find() || log.count() == 0) {
		page.write();
		return;
	}
	season_int = m.group(1).to_int();

	// load memory
	fite[int] fites;
	int[string,int,int] scores;
	file_to_map('flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt', fites);
/*	string[string] fmem = form_fields();
	if (fmem contains 'radio')
		fmem.map_to_file('flogger.'+my_name().to_lower_case()+'.pref');
	else {
		file_to_map('flogger.'+my_name().to_lower_case()+'.pref', fmem);
		if (fmem.count() != 1) {
			fmem = { 'radio': 'noblue' };
			fmem.map_to_file('flogger.'+my_name().to_lower_case()+'.pref');
		}
	}
*/

	// tally wins/losses
	// save to file sometimes
	int got, scored;
	try {
		foreach idx,grp,lid in log {
			if (grp==1) {
				int L = lid.to_int();
				if (!(fites contains L)) {
					fites[L] = examine_fite(L);
					got++;
				}
				foreach mini,winner in fites[L].R
					scores[int_to_stance[mini], fites[L].A, winner]++;
				scored++;
				if (got > 0 && got % 50 == 0) {
					print("Flogger cached "+got+" more fites");
					map_to_file(fites, 'flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt');
				}
			}
		}
	}

	// save, render
	finally {
		map_to_file(fites, 'flogger.'+season_int+'.'+my_name().to_lower_case()+'.txt');
		page = page.append_child('<head>(.+)</head>', '<style>table table table tr td { vertical-align: middle; padding: 0.5px 2px; } table table table td span { display:block; width:5em; border: 1px solid black; padding: 2px 0; font-weight: bold; color: white; text-shadow: 0px 0px 5px black;} </style>');
		string intro = page.split_string('<tr><th>Name</th>')[0];
		string[int] mid = page.xpath('//table//table//table//tr');
		string outro = '</table><p><small>' + page.split_string('</td></tr></table><p><small>')[1];
		
		intro.write();
		foreach i,s in mid {
			if (i == 0)
				s = s.append_child('<tr>(.+)</tr>', "<th>Attacking</th><th>Defending</th>");	
			else foreach mini in current_pvp_stances() if (s.contains_text(mini) || s.contains_text(mini.replace_string("'",'&apos;'))) {
				int a,x;
				if (scores[mini,1,1] + scores[mini,1,0] > 0)
					a = (100 * scores[mini,1,1]) / (scores[mini,1,1] + scores[mini,1,0]);
				if (scores[mini,0,1] + scores[mini,0,0] > 0)
					x = (100 * scores[mini,0,1]) / (scores[mini,0,1] + scores[mini,0,0]);
				string tattrs = 'align="center"';
				string spattrs = 'style="background-color:';
				s = s.append_child('<tr class="small">(.+)</tr>', `<td {tattrs}><span {spattrs}{colorize(a)+';"'}>{a}%</span></td><td {tattrs}><span {spattrs}{colorize(x)+';"'}>{x}%</span></td>`);
			}
			s.write();
		}
		string footnote = `</small></p><p><small>** Attacking and defending win rates are over {scored} recent fights.</small></p>`;
		outro.append_child('<p>(.+)</p>', footnote).write();
	}
}
