#include <idc.idc>

static write_prologue(file) {
	fprintf(file,
		"return {\n"
	);
}

static set_function(file, address, name) {
	fprintf(file,
		"\t[\"%s\"] = 0x%X,\n",
		name,
		address
	);
}

static set_data(file, address, name) {
	fprintf(file,
		"\t[\"%s\"] = 0x%X,\n",
		name,
		address
	);
}

static write_epilogue(file) {
	fprintf(file,
		"\tnull = 0 -- we need a specific end because commas are annoying\n}\n"
	);
}

static main() {
	auto outFile, address, lastFunc;
	
	outFile = fopen(AskFile(1, "*.lua", "output lua file"), "w");
	
	write_prologue(outFile);
	
	address  = 0x8000000; // ROM Start
	
	for (address = NextFunction(address); address != BADADDR; address = NextFunction(address)) {
		auto flags = GetFlags(address);

		//*		
		if (hasName(flags)) // check for user-named function
			set_function(outFile, address, Name(address));
	}

	for (address = 0x2000000; address != BADADDR; address = NextNotTail(address)) {
		flags = GetFlags(address);
		
		// (strlen(GetString(address, -1, GetStringType(address))) == 0)
		
		if (hasName(flags) && isData(flags)) {
			auto name = Name(address);
			
			if (strstr(name, "a") != 0 & strstr(name, "str") != 0)
				set_data(outFile, address, name);
		}
	}

	write_epilogue(outFile);
	
	fclose(outFile);
}

