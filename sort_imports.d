#!/usr/bin/env rdmd

import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
       std.parallelism, std.path, std.process, std.range, std.regex,
       std.stdio, std.string;

import dscanner, file_tester;

auto countLines(R)(R lines)
{
    return lines
            .until!(l => !(l.canFind("import") || l.length == 0))
            .filter!(l => l.canFind("import"))
            .walkLength;
}

void sortImportWithinLines(string[] lines)
{
    auto sorted = lines
                    .filter!(l => l.canFind("import"))
                    .array
                    .sort()
                    .release;
    lines[] = sorted;
}

void main(string[] args)
{

    string inFileList = "list";
    string repoDir = getcwd;

    getopt(args, "listfile|l", &inFileList,
                 "repodir|d", &repoDir);

    auto replacements = inFileList.parseOutput;
    foreach (f; replacements.byKeyValue)
    {
        auto tester = FileTester(repoDir, f.key, ["rdmd",
            "-c",
            "--compiler=/home/xsebi/dlang/dmd-master-2017-02-20/linux/bin64/dmd",
            "-main", "-unittest"]);
        with (tester)
        foreach (e; f.value)
        {
            if (!lines[e.line].canFind("import"))
            {
                writeln("dscanner error in %s", e.line);
                continue;
            }
            // search import lines above
            auto before = lines[0 .. e.line].retro.countLines;
            auto after = lines[e.line + 1.. $].countLines;

            writefln("line: %s (before: %d, after: %d)", e.line, before, after);
            sortImportWithinLines(lines[e.line - before .. e.line + after + 1]);
        }
        break;
    }
}
