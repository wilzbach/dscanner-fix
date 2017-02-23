#!/usr/bin/env rdmd

void main(string[] args)
{
    import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
           std.parallelism, std.path, std.process, std.range, std.regex,
           std.stdio, std.string;

    import dscanner, file_tester;

    string inputDir = getcwd;
    string[] ignoredFiles;

    auto helpInfo = getopt(args,
        "inputdir|i", "Folder to start the recursive search for (can be a single file)", &inputDir,
        "ignore", "Comma-separated list of files to exclude (partial matching is supported)", &ignoredFiles);

    if (helpInfo.helpWanted)
    {
        return defaultGetoptPrinter(`Replaces $(D code) syntax`, helpInfo.options);
    }

    DirEntry[] files;
    if (inputDir.isFile)
    {
        files = [DirEntry(inputDir)];
        inputDir = ".";
    }
    else
    {
        files = dirEntries(inputDir, SpanMode.depth).filter!(
        a => a.name.endsWith(".d") && !a.name.canFind(".git")).array;
    }

    auto re = regex(`[$]\(D ([^)]*)\)`);

    foreach (file; files)
    if (!ignoredFiles.any!(x => file.name.canFind(x)))
    {
        auto tester = FileTester(inputDir, file.name);
        with (tester)
        foreach (i, line; lines)
        {
            if (!line.matchFirst(re).empty)
            {
                lines[i] = replaceMacro(line);
                writeln(lines[i]);
            }
        }
    }
}

// mini ddoc lexer
auto replaceMacro(string l)
{
    import std.array : appender;
    import std.algorithm;
    import std.conv;

    int p; // level of parentheses
    bool inDdoc;
    int ddocPLevel;

    dstring line = l.to!dstring; // random access

    auto app = appender!dstring;
    for (int i = 0; i < line.length; i++)
    {
        dchar c = line[i];
        switch (c) {
            case '(':
                p++;
                goto default;
            case ')':
                if (inDdoc && p == ddocPLevel)
                {
                    app ~= "`";
                    inDdoc = false;
                    break;
                }
                p--;
                goto default;
            case '$':
                if (line[i .. $].startsWith(`$(D `))
                {
                    inDdoc = true;
                    ddocPLevel = ++p;
                    i += 3; // "(D "
                    app ~= "`";
                    break;
                }
                goto default;
            default:
                app ~= c;
        }
    }
    return app.data.to!string;
}
