import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
       std.parallelism, std.path, std.process, std.range, std.regex,
       std.stdio, std.string, std.uuid;

struct FileTester
{
    string[] lines;
    string destFile, path;
    string[] cmd;
    string tmpDir;
    size_t moduleLine;

    this(string repoDir, string path, string[] cmd)
    {
        this.path = path;
        writeln("open: ", path);

        destFile = buildPath(repoDir, path);
        lines = File(destFile).byLineCopy.array;
        this.cmd = cmd;
        tmpDir = buildPath(tempDir, "file_tester", path.dirName.replace("/", "_"));
        tmpDir.mkdirRecurse;
        patchModuleLine;
    }

    // simply patch it to "v2"
    private void patchModuleLine()
    {
        foreach (i, ref line; lines)
        {
            if (line.startsWith("module"))
            {
                moduleLine = i;
                lines[i] = lines[i][0 .. $ - 1] ~ "2;";
                break;
            }
        }
    }

    private void unpatchModuleLine()
    {
        lines[moduleLine] = lines[moduleLine][0 .. $ - 2] ~ ";";
    }

    ~this()
    {
        unpatchModuleLine;

        // dump final changes
        auto tmpFile = writeLinesToFile;
        tmpFile.copy(destFile);
        tmpFile.remove;
        tmpDir.rmdirRecurse;
    }

    auto writeLinesToFile(string s = null) {
        if (!s.length)
            s = buildPath(tmpDir, randomUUID.to!string.replace("-", "") ~ ".d");

        writeln("trying: ", path);
        auto outFile = File(s, "w");
        // dump file
        foreach (line; lines)
            outFile.writeln(line);
        outFile.flush;

        return s;
    }

    bool testChange(size_t line, string newLine)
    {
        auto oldLine = lines[line];
        lines[line] = newLine;
        auto tmpFile = writeLinesToFile;

        //auto make = execute(["rdmd", "-main", "-unittest", "--compiler=../dmd/src/dmd", destFile],
        //null, Config.none, size_t.max, repoDir);

        auto cmdC = cmd.dup;
        cmdC ~= tmpFile;
        // execute in the directory of dmd (no import conflicts)
        auto make = execute(cmdC, null, Config.none, size_t.max, cmd[0].dirName);
        writeln(make.output);
        if (make.status == 0)
            {
            writefln("Success for line: %d", line);
            return true;
        }
        else
            {
            writefln("Error for line: %d", line);
            lines[line] = oldLine;
            return false;
        }
    }
}
