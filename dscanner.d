module dscanner;

import std.conv;
import std.file;
import std.regex;
import std.stdio;

struct Entry
{
    size_t line;
    size_t column;
}

// returns hashmap with list of replacements for each file entry
Entry[][string] parseOutput(string inFileList)
{
    Entry[][string] replacements;
    auto re = regex(`(.+)\(([0-9]+):([0-9]+)\)`);
    // sortedness from dscanner is expected
    foreach (entry; File(inFileList).byLineCopy)
    {
        auto m = entry.matchFirst(re);
        if (m.length < 3)
            continue;
        const key = m[1];
        const line = m[2].to!size_t - 1; // dscanner lines start with 1
        replacements[key] ~= Entry(line, m[3].to!size_t);
    }
    return replacements;
}
