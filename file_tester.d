import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
       std.parallelism, std.path, std.process, std.range, std.regex,
       std.stdio, std.string;

struct FileTester
{
    string[] lines;
    string tmpFile, destFile, path;
    string[] cmd;

    this(string repoDir, string path, string[] cmd)
    {
        this.path = path;
        tmpFile = tempDir ~ "/" ~ path.replace("/", "_");
        writeln("open: ", path);

        destFile = buildPath(repoDir, path);
        lines = File(destFile).byLineCopy.array;
        this.cmd = cmd;
    }

    ~this()
    {
        // dump final changes
        writeFile;
    }

    void writeFile() {
        writeln("trying: ", path);
        auto outFile = File(tmpFile, "w");
        // dump file
        foreach (line; lines)
            outFile.writeln(line);
        outFile.flush;
        outFile.flush;
        tmpFile.copy(destFile);
        tmpFile.remove;
    }

    bool testChange(size_t line, string newLine)
    {
        auto oldLine = lines[line];
        lines[line] = newLine;
        writeFile;

        //auto make = execute(["rdmd", "-main", "-unittest", "--compiler=../dmd/src/dmd", destFile],
        //null, Config.none, size_t.max, repoDir);

        auto cmdC = cmd.dup;
        cmdC ~= destFile;
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
