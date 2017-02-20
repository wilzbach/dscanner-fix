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
    defaultPoolThreads(20);
    foreach (f; replacements.byKeyValue.parallel(1))
    {
        auto tester = FileTester(repoDir, f.key, [
            "/home/xsebi/dlang/dmd-master-2017-02-20/linux/bin64/dmd",
            "-unittest",
            "-main",
            "-c",
            "-dip25",
            //"-run"
        ]);
        with (tester)
        foreach (e; f.value)
        {
            // try to avoid false positives at all costs
            if (lines[e.line].canFind("="))
            {
                auto tmp = lines[e.line].splitter("=");
                string proposed = tmp.front.replace(" auto ", " immutable ") ~ "=" ~ tmp.dropOne.join("=");
                testChange(e.line, proposed);
            }
        }
    }
}
