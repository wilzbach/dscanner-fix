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
    foreach (f; replacements.byKeyValue)
    {
        auto tester = FileTester(repoDir, f.key, ["rdmd",
            "--compiler=/home/xsebi/dlang/dmd-master-2017-02-20/linux/bin64/dmd",
            "-main", "-unittest"]);
        with (tester)
        foreach (e; f.value)
        {
            if (!lines[e.line].canFind("unittest"))
            {
                writeln("dscanner error in %s", e.line);
                continue;
            }
            auto parts = lines[e.line].split("unittest");
            if (!parts[0].canFind("@safe", "@system"))
            {
                auto proposed = parts[0] ~ "@safe unittest" ~ parts[1];
                if (!testChange(e.line, proposed))
                {
                    lines[e.line] = parts[0] ~ "@system unittest" ~ parts[1];
                }
            }
        }
        break;
    }
}
