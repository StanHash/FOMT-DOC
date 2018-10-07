#include <idc.idc>

static write_prologue(file) {
	fprintf(file,
		"function fill_db(db)\n"
	);
}

static set_function(file, address, name) {
	fprintf(file,
		"\tdb:set_function(0x%X, \"%s\")\n",
		address,
		name
	);
}

static write_epilogue(file) {
	fprintf(file,
		"end\n"
	);
}

static main() {
	auto outFile, address;
	
	outFile = fopen(AskFile(1, "*.lua", "output lua file"), "w");
	
	write_prologue(outFile);
	
	address = 0x8000000; // ROM Start
		
	for (address = NextFunction(address); address != BADADDR; address = NextFunction(address)) {
		set_function(outFile, address, Name(address));

		/*
		auto flags = GetFlags(address);
		
		if (hasName(flags)) // check for user-named function
			fprintf(outFile, "SET_ABS_FUNC %s, 0x%X\n", Name(address), address+GetReg(address, "T")); // */
	}
	
	write_epilogue(outFile);
	
	fclose(outFile);
}

