#!/usr/bin/env rdmd

auto parenDiff(S)(S ss)
{
    auto count = 0;
    foreach (s; ss)
    {
        switch (s)
        {
            case '(': count++; break;
            case ')': count--; break;
            default:
        }
    }
    return count;
}

void main(string[] args)
{
    import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
           std.path, std.range, std.regex, std.stdio, std.string;

    string inFileList = "list";
    string repoDir = getcwd;

    getopt(args, "listfile|l", &inFileList,
                 "repodir|d", &repoDir);

    struct Entry
    {
        size_t line;
        size_t column;
        size_t indent;
    }

    Entry[][string] replacements;
    auto re = regex(`(.+)\(([0-9]+):([0-9]+)\)\[warn\]: (.*):([0-9+])$`);
    foreach (entry; File(inFileList).byLineCopy)
    {
        // filter for dscanner warning
        auto m = entry.matchFirst(re);
        if (m.length < 3)
            continue;
        if (!m[4].canFind("indentation"))
            continue;

        const key = m[1];
        // dscanner starts at 1
        replacements[key] ~= Entry(m[2].to!size_t - 1, m[3].to!size_t, m[5].to!size_t);
    }

    foreach (key, value; replacements.byPair)
    {
        auto tmpFile = tempDir.buildPath(key.replace("/", "_"));
        auto destFile = repoDir.buildPath(key);
        auto outFile = File(tmpFile, "w");
        scope(exit) {
            tmpFile.copy(destFile);
            tmpFile.remove;
        }

        writeln("open: ", key);
        auto lines = File(destFile).byLineCopy.array;
        foreach (i, line; lines)
        {
            auto index = value.countUntil!(c => c.line == i);
            if (index >= 0)
            {
                auto indent = value[index].indent;
                bool separateLine = line.find!(c => !c.isWhite).startsWith("if ");
                auto pdiff = 0;

                if (separateLine)
                {
                    lines[i] = ' '.repeat(indent).to!string ~ line.stripLeft;
                    pdiff = parenDiff(line);
                }
                else
                {
                    auto ifParts = line.split("if ");
                    if (line.canFind("if "))
                    {
                        // if is at the end of the current line
                        if (ifParts[0].strip.length > 0)
                        {
                            lines[i] = ' '.repeat(indent).to!string;
                            lines[i] ~= ifParts[0].strip ~ "\n";
                        }

                        lines[i] ~= ' '.repeat(indent).to!string ~ "if ";
                        if (ifParts.length >= 1)
                        {
                            auto s = ifParts[1..$].joiner("if ").to!string;
                            lines[i] ~= s;
                            pdiff = s.parenDiff;
                        }
                    }
                    else
                    {
                        auto prevLineParts = lines[i - 1].split(" if");
                        bool isAlone = lines[i - 1].find!(c => !c.isWhite).startsWith("if ");
                        if (!isAlone)
                            lines[i - 1] = prevLineParts[0] ~ "\n";
                        else
                            lines[i - 1] = "";

                        lines[i - 1] ~= ' '.repeat(indent).to!string ~ "if" ~ prevLineParts[1];

                        // check for following indentation
                        pdiff = prevLineParts[1].parenDiff + lines[i].parenDiff;
                        lines[i] = ' '.repeat(indent + 4).to!string ~ lines[i].stripLeft;
                    }
                }

                // check for following lines
                for (auto j = i + 1; pdiff > 0; j++)
                {
                    pdiff += lines[j].parenDiff;
                    lines[j] = ' '.repeat(indent + 4).to!string ~ lines[j].stripLeft;
                }
            }
        }

        // dump file
        foreach (line; lines)
            outFile.writeln(line);
        outFile.flush;
    }
}
