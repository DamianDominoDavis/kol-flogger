// study, grasshopper
// learn over one thousand fights
// which kung fu is best

int[string] stance_to_int;
string[int] int_to_stance;
foreach s in current_pvp_stances() {
	int_to_stance[int_to_stance.count()] = s;
	stance_to_int[s] = int_to_stance.count() - 1;
}

record fite {
	int A;
	int[int] R;
};

fite examine_fite(int lid) {
	fite out;
	buffer b = visit_url("peevpee.php?action=log&ff=1&lid="+lid+"&place=logs&pwd", false);
	string[int] fighters = b.xpath("//div[@class='fight']/a/text()");
	string[int] stances = b.xpath("//tr[@class='mini']/td/center/b/text()");
	string[int] results = b.xpath("//tr[@class='mini']/td[1]");
	out.A = (fighters[0].to_lower_case() == my_name().to_lower_case()).to_int();
	foreach i,mini in stances
		out.R[stance_to_int[mini]] = (!(out.A.to_boolean() ^ results[i].contains_text('youwin'))).to_int();
	return out;
}

string colorize(string key, int x) {
	string[string] fmem;
	file_to_map('flogger.pref', fmem);
	if (key == 'nored' || fmem['radio'] == 'nored')
		return `rgb({50-(x>50?x-50:50-x)}%,{x}%,{100-x}%)`;
	if (key=='nogreen' || fmem['radio'] == 'nogreen')
		return `rgb({100-x}%,{50-(x>50?x-50:50-x)}%,{x}%)`;
	return `rgb({100-x}%,{x}%,{50-(x>50?x-50:50-x)}%)`;
}

void study() {
	fite[int] fites;
	string season = visit_url('peevpee.php?place=rules', false).xpath('//table//table//p[1]/text()')[0];
	matcher m = '\(\\d+\)'.create_matcher(season);
	if (!m.find())
		abort('Unseasonal.');
	file_to_map('fites_'+m.group(1)+'.txt', fites);
	string[string] fmem = form_fields();
	if (fmem contains 'radio')
		fmem.map_to_file('flogger.pref');
	else {
		file_to_map('flogger.pref', fmem);
		if (fmem.count() != 1) {
			fmem = { 'radio': 'noblue' };
			fmem.map_to_file('flogger.pref');
		}
	}

	// compare log to file
	// fetch only what isn't saved
	// cancel with ESCAPE
	string[int,int] log = visit_url('peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1', false).group_string("action=log&ff=1&lid=\(\\d\+\)&place=logs");
	int[string,int,int] scores;
	int got;
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
				if (got > 0 && got % 50 == 0) {
					print("Saved "+got+" new records");
					map_to_file(fites, 'fites_'+m.group(1)+'.txt');
				}
			}
		}
	}

	// store to memory
	// pretty-print aggregate scores
	// see what you have wrought
	finally {
		map_to_file(fites, 'fites_'+m.group(1)+'.txt');
		writeln("<style> table, div { margin: 0 auto; text-align: center; } ");
		writeln("  p, td, th{ text-align:center; vertical-align:middle; color:black; font-family:arial; font-size: 0.8em; }");
		writeln("  table { padding: 0px; border: 1px solid blue; }");
		writeln("  table tr:first-child { background-color:blue; }");
		writeln("  table tr:first-child td, td.wl, p a span { color:white; font-weight: bold; }");
		writeln("  td, th { border: 0; padding: 2px 5px; }");
		writeln("  td.wl { border: 1px solid black; width: 4em; }");
		writeln("  td.wl, p a span { padding: 0 3px; text-shadow: 0px 0px 5px black; }");
		writeln("  input:nth-child(-n+3) { border: 0px; } ");
		writeln("  .container {  display: inline; position: relative; padding-left: 35px; margin-bottom: 12px; cursor: pointer; font-size: 22px; -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; }");
		writeln("  .container input { position: absolute; opacity: 0; cursor: pointer; }");
		writeln("  .checkmark { position: absolute; top: 0; left: 0; height: 25px; width: 25px; border-radius: 50%; }");
		writeln("  label:nth-child(1) .checkmark { background-color: #ff0000; }");
		writeln("  label:nth-child(2) .checkmark { background-color: #00ff00; }");
		writeln("  label:nth-child(3) .checkmark { background-color: #0000ff; }");
		writeln("  .container:hover input ~ .checkmark { background-color: #cccccc; }");
		writeln("  .container input:checked ~ .checkmark { background-color: #666666; }");
		writeln("  .checkmark:after { content: ''; position: absolute; display: none; }");
		writeln("  .container input:checked ~ .checkmark:after { display: block; }");
		writeln("  .container .checkmark:after { top: 9px; left: 9px; width: 8px; height: 8px; border-radius: 50%; background: #cccccc; }");
		writeln("</style>");
		writeln("<div><p>" + (got>0? "Saved "+got+" new records.":"&nbsp;") + "</p></div>");
		writeln("<table><tbody><tr><td colspan='3'>Flogger</td></tr>");
		writeln("<tr><td colspan='3'>Your WIN rate by stance in <strong>"+fites.count()+"</strong> recent fites</td></tr>");
		writeln("<tr><td>Attacking</td><td></td><td>Defending</td></tr>");
		print("Your WIN rate by stance in "+fites.count()+" recent fites:");
		foreach s in current_pvp_stances() {
			int a,x;
			if (scores[s,1,1] + scores[s,1,0] > 0)
				a = (100 * scores[s,1,1]) / (scores[s,1,1] + scores[s,1,0]);
			if (scores[s,0,1] + scores[s,0,0] > 0)
				x = (100 * scores[s,0,1]) / (scores[s,0,1] + scores[s,0,0]);
			writeln("<tr><td class='wl' style='background-color:"+colorize(form_field('radio'),a)+"'>"+a+"%</td>");
			writeln("<th>"+s+"</th>");
			writeln("<td class='wl' style='background-color:"+colorize(form_field('radio'),a)+"'>"+x+"%</td></tr>");
			print(`{a}% ATK || {x}% DEF -- {s}`);
		}
		writeln("</tbody></table>");
		writeln("<div><p><form method='POST' action='"+__FILE__+"'>");
		writeln("<label class='container'>");
		writeln("  <input type='radio' name='radio' value='nored' onchange='this.form.submit();'"+(fmem['radio']=='nored'?" checked ":" ")+">");
		writeln("  <span class='checkmark'></span>");
		writeln("</label>");
		writeln("<label class='container'>");
		writeln("  <input type='radio' name='radio' value='nogreen' onchange='this.form.submit();'"+(fmem['radio']=='nogreen'?" checked ":" ")+">");
		writeln("  <span class='checkmark'></span>");
		writeln("</label>");
		writeln("<label class='container'>");
		writeln("  <input type='radio' name='radio' value='noblue' onchange='this.form.submit();'"+(fmem['radio']=='noblue'?" checked ":" ")+">");
		writeln("  <span class='checkmark'></span>");
		writeln("</label>");
		writeln("</form></p></div>");
	}
}

void main() {
	study();
}
