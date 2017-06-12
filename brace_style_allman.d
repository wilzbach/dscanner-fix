#!/usr/bin/env rdmd

import dscanner, file_tester;
import std.algorithm, std.array, std.ascii, std.conv, std.file, std.getopt,
       std.path, std.range, std.regex, std.stdio, std.string;

void fixLeft(ref string[] lines, size_t pos, ref int linesShift)
{
    // remove "{"
    auto parts = lines[pos].split("{");
    lines[pos] = text(parts[0 .. $ - 1].joiner("{"), parts[$ - 1]).stripRight;
    // detect indent
    auto indentLevel = lines[pos].countUntil!(e => !e.isWhite);
    if (indentLevel >= 0)
    {
        lines.insertInPlace(pos + 1, text(' '.repeat(indentLevel), "{"));
        linesShift++;
    }
    else
    {
        // ignore false positives
        lines[pos] = "{";
    }
}

void fixRight(ref string[] lines, size_t pos, ref int linesShift)
{
    // remove "}"
    auto parts = lines[pos].split("}");
    lines[pos] = parts[0 .. $ - 1].joiner("}").text.stripRight;

    // detect indent
    auto indentLevel = max(0, lines[0 .. pos].retro.find!(l => l.canFind("{")).front.countUntil!(e => !e.isWhite));
    // insert "}"
    auto blankLine = text(' '.repeat(indentLevel), "}");
    if (parts.length > 1)
        blankLine ~= parts[$ - 1];

    lines.insertInPlace(pos + 1, blankLine);
    linesShift++;
}

void main(string[] args)
{
    string inFileList = "list";
    string repoDir = getcwd;

    getopt(args, "listfile|l", &inFileList,
                 "repodir|d", &repoDir);

    auto replacements = inFileList.parseOutput;
    foreach (key, values; replacements.byPair)
    {
        //if (key != "std/algorithm/mutation.d")
            //continue;

        auto tester = FileTester(repoDir, key, null);
        int linesShift = 0;

        with (tester)
        foreach (v; values)
        {
            auto pos = v.line + linesShift;
            //writeln(v, lines[pos]);

            if (lines[pos].canFind("{"))
                fixLeft(lines, pos, linesShift);
            else if (lines[pos].canFind("}"))
                fixRight(lines, pos, linesShift);
            else
            {
                // shifts
                if (lines[pos - 1].canFind("{"))
                    pos--, linesShift--;
                if (lines[pos + 1].canFind("{"))
                    pos++, linesShift++;
                else if (lines[pos + 2].canFind("{"))
                    pos += 2, linesShift += 2;

                fixLeft(lines, pos, linesShift);
            }
        }
    }
}
