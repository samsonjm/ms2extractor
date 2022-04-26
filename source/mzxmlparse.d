/* Opens an MZxml file and parses the data from it
 *
 * Author: Jonathan Samson
 */
import std.utf;
import std.stdio;
import std.exception;
import core.stdc.errno;
import std.regex;
import std.string;
import std.getopt;

string read_file(string name_of_file)
/* Reads the file into a string.
 * Arguments:
 * 	file_stream - The name of the file to read.
 *
 * Returns:
 *	file_contents - The contents of the file.
 */
{
	string file_contents = "";
	try 
	{
		auto file = File(name_of_file, "r");
		string line;
		while ((line = file.readln()) !is null)
		{
			file_contents ~= line;
		}
		file.close();
	}
	catch(ErrnoException e)
	{
		switch(e.errno)
		{
			case EPERM:
			case EACCES:
			{
				writeln("Permission denied for reading file");
				break;
			}
			case ENOENT:
			{
				writeln("File does not exist");
				break;
			}
			default:
				//Handles other errors
				break;
		}
	}	
	return file_contents;
}
unittest
{
	assertThrown!FileException(parse_mzXML("notafile.fake"));
}

string read_mzXML_file(string name_of_file)
/* Reads the data in from am mzXML file to a string.
 * Arguments:
 * 	file_stream - The name of the file to read.
 *
 * Returns:
 *	file_contents - The contents of the file.
 */
{
	enforce(
			name_of_file[$-6..$] == ".mzXML",
			"You muse use an .mzXML file"
	);
	return read_file(name_of_file);
}
unittest
{
	assert!ExceptionThrown(read_mzXML_file("example.txt");
}

string extract_scans(string mzXML_contents)
/* Extracts scans from the contents of an mzXML file.
 * Arguments:
 *	mzXML_contents - The contents of an mzXML file
 *
 * Returns:
 *	scans - The scans of the mzXML_contents file.
 */
{
	string scans;
	auto scan_regex = ctRegex!(`    <scan num=(.|\n)*scan>`, "m");
	foreach(location; mzXML_contents.matchAll(scan_regex))
		scans ~= location.hit;
	return scans;
}

string extract_ms2_scans(string mzXML_contents)
/* Extracts only MS2 scans from the mzXML string.
 * Arguments:
 *	mzXML_contents - The contents of an mzXML file.
 *
 * Returns:
 *	ms2_scans - The MS2 scans of the mzXML_contents file.
 */
{
	string ms2_scans;
	auto scan_regex = ctRegex!(
		`^    <scan num=".+"(.*\n){3}\W*msLevel="2"(.|\n)*?scan>`,
		"m");
	foreach(location; mzXML_contents.matchAll(scan_regex))
		ms2_scans ~= location.hit ~ "\n";
	ms2_scans = ms2_scans[0..$-1]; // Removes the trailing \n 
	return ms2_scans;
}

string extract_header_metadata(string mzXML_contents)
/* Extracts the metadata from the header of an mzXML file.
 * Arguments:
 *	mzXML_contents - The contents of an mzXML file.
 *
 * Returns:
 *	header_data - The header metadata of the mzXML file.
 */
{
	string header_data;
	auto header_regex = ctRegex!(`(<\?xml(.*\n)*\s{4}</dataProcessing>\n)`);
	auto header = matchFirst(mzXML_contents, header_regex);
	header_data = header[0];
	return header_data;
}

string extract_footer_metadata(string mzXML_contents)
/* Extracts the metadata from the footer of an mzXML file.
 * Arguments:
 *	mzXML_contents - The contents of an mzXML file.
 *
 * Returns:
 *	footer_data - The footer metadata of the mzXML file.
 */
{
	string footer_data;
	auto footer_regex = ctRegex!(`^\s*<\/msRun>(.*\n*)*`, "m");
	auto footer= matchFirst(mzXML_contents, footer_regex);
	footer_data = footer[0];
	return footer_data;
}

void write_file(string name_of_file, string new_contents)
/* Writes the string to a file.
 * Arguments:
 *	name_of_file - The file to write to.
 *	new_contents - The contents to write into the file.
 */
{
	string file_contents = "";
	try 
	{
		auto file = File(name_of_file, "w");
		file.write(new_contents);
		file.close();
	}
	catch(ErrnoException e)
	{
		switch(e.errno)
		{
			case EPERM:
			case EACCES:
			{
				writeln("Permission denied for writing file");
				break;
			}
			case ENOENT:
			{
				writeln("File does not exist");
				break;
			}
			default:
				//Handles other errors
				break;
		}
	}	
	return;
}

bool extract_ms2(
	string input_file, 
	string output_file,
	bool use_metadata,
	bool all_scans)
{
	string scans;
	string contents = read_mzXML_file(input_file);
	if(all_scans)
		scans = extract_scans(contents);
	else
		scans = extract_ms2_scans(contents);
	if(use_metadata == true)
	{
		string header = extract_header_metadata(contents);
		string footer = extract_footer_metadata(contents);
		scans = header ~ scans ~ footer;
	}
	write_file(output_file, scans);
	return true;
}

/*
void main(string[] args)
{
	string input_file;
	string output_file;
	bool use_metadata = false;
	bool all_scans = false;
	string scans;
	
	auto helpInformation = getopt(
		args,
		"all|a", "Include all scans", &all_scans,
		"input|i", "(string) The input file in .mzXML format", &input_file,
		"metadata|m", "Include metadata", &use_metadata,
		"output|o", "(string) The file to output to", &output_file);
	if(helpInformation.helpWanted)
	{
		defaultGetoptFormatter(
			stdout.lockingTextWriter(),
			"Extracts MS scans from a mzXML file",
			helpInformation.options, 
			"  %*s\t%*s%*s%s\n");
		return;
	}

	string contents = read_mzXML_file(input_file);
	if(all_scans)
		scans = extract_scans(contents);
	else
		scans = extract_ms2_scans(contents);
	if (use_metadata == true)
	{
		string header = extract_header_metadata(contents);
		string footer = extract_footer_metadata(contents);
		scans = header ~ scans ~ footer;
	}
	write_file(output_file, scans);
}
*/
