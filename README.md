Auto-fix DScanner warnings
==========================

This repo contains a couple of scripts that can help to automatically fix DScanner
warnings.
At the moment the process is semi-automated. You need to collect the list of
DScanner warnings yourself:

Available fixes
---------------

script name       | DScanner config       			 | Description
--------------------------------------------------------------------------------
`system_unittext` | `explicitly_annotated_unittests` | sets all unattributed unittests to either `@safe` or `@system` (it will try to compile every change)
`if_constraint`   | [WIP][if_constrainits]			 | sets the indentation level of `if` constraints to the same of the declaration
`immutable`       | `could_be_immutable_check`		 | tries to set all potentially immutable variables to `const` (it will try to compile every change, WIP)

[if_constraints]: https://github.com/Hackerpilot/Dscanner/pull/394

Gotchas
-------

- this project is in alpha status and you may need to do some manual corrections.
- use `nightly` builds (`curl -L https://dlang.org/install.sh | bash -s dmd-nightly`)

1) Enable the DScanner check
----------------------------

In the `.dscanner.ini`, set the according check to `enable`, e.g.:

```
could_be_immutable_check="enabled"
```

1) Generate a file with all Dscanner warnings
---------------------------------------------

For Phobos this can be conveniently done with:

```
make -f posix style
```

Please check the output file.
You may need to manually cut of the lines in the beginning)

3) Fix the warnings
-------------------

Simply run:

```
rdmd <path-to-replacement-script> --repodir <e.g. phobos> --listfile <listfile>
```
