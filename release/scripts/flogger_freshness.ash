// this is broken out into its own file to make mafia ask for CLI input.
// this ought to be form action worked from the relay browser.
void main(int number) {
	if (number < 1) {
		print('Nonsense.', 'red');
		return;
	}
	string file = "flogger." + my_name().to_lower_case() + ".pref";
	string[string] memory;
	file_to_map(file, memory);
	memory["freshness"] = number.to_string();
	if (memory.map_to_file(file))
		print("flogger will use up to the most " + memory["freshness"].to_int() + " freshest fites in memory");
	else
		print("failed to save file: /data/" + file, 'red');
}
