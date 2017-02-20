#!/usr/bin/env rdmd

void main(string[] args)
{
    import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
           std.parallelism, std.path, std.process, std.range, std.regex,
           std.stdio, std.string;

    import dscanner, file_tester;

    string inFileList = "list";
    string repoDir = getcwd;

    getopt(args, "listfile|l", &inFileList,
                 "repodir|d", &repoDir);

    auto replacements = inFileList.parseOutput;

    // runs all replacement checks with the maximal thread pool
    foreach (e; replacements.byPair.parallel)
    {
        auto tester = FileTester(repoDir, e.key, ["rdmd", "-main", "-unittest"]);
        with (tester)
        foreach (entry; values)
        {
            auto line = entry.line - 1; // dscanner lines start with 1
            // try to avoid false positives at all costs
            if (lines[line].canFind("="))
            {
                auto tmp = lines[line].splitter("=");
                string proposed = tmp.front.replace(" auto ", " const ") ~ "=" ~ tmp.dropOne.join("=");
                testChange(line, proposed);
            }
        }
    }
}
