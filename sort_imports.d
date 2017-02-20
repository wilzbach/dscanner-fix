#!/usr/bin/env rdmd

import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
       std.parallelism, std.path, std.process, std.range, std.regex,
       std.stdio, std.string, std.utf;

import dscanner, file_tester;

/**
Import on multiple lines are tricky
*/
auto countLines(R)(R lines)
{
    size_t length = 0;
    bool continuesOnNextLine;
    foreach (line; lines)
    {
        if (line.length == 0)
            break;
        if (!line.canFind("import") && !continuesOnNextLine)
            break;

        length++;
        continuesOnNextLine = !line.endsWith(";");
    }
    return length;
}

void sortImportWithinLines(string[] lines)
{
    static struct Entry {
        string[] lines;
        string key;
    }

    Entry[] ll;
    foreach (line; lines)
    {
        if (line.canFind("import "))
            ll ~= Entry([line], line
                .byCodeUnit
                .findSplitAfter("import ")[1]
                .filter!(a => a.isAlpha)
                .until(':')
                .to!string);
        else
        {
            ll.back.lines ~= line;
        }
    }

    // this should be valid:
    // import std.experimental.allocator;
    // import std.experimental.allocator.common;
    auto sorted = ll.sort!((a, b) => a.key < b.key)
                    .release
                    .map!(e => e.lines)
                    .joiner
                    .array;
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
        //if (f.key != "std/experimental/allocator/typed.d")
            //continue;

        //if (f.key != "std/windows/registry.d")
            //continue;

        auto tester = FileTester(repoDir, f.key, ["rdmd",
            "-c",
            "-w",
            "-dip25",
            "--compiler=/home/xsebi/dlang/dmd-master-2017-02-20/linux/bin64/dmd",
            "-main", "-unittest"]);

        bool[size_t] hasBeenSorted;
        with (tester)
        foreach (e; f.value)
        {
            if (e.line in hasBeenSorted)
                continue;
            if (!lines[e.line].canFind("import"))
            {
                writefln("dscanner error (l:%d): %s", e.line, lines[e.line]);
                continue;
            }
            // search import lines above
            auto before = lines[0 .. e.line + 1].retro.countLines - 1;
            auto after = lines[e.line .. $].countLines - 1;

            writefln("line: %s (before: %d, after: %d)", e.line, before, after);
            sortImportWithinLines(lines[e.line - before .. e.line + after + 1]);
            foreach (i; e.line - before .. e.line + after + 1)
                hasBeenSorted[i] = true;
        }
    }
}
