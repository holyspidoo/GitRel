# GitRel
Dart command line tool that checks GitHub repos for new releases. Can also check all the Starred repos of a github user for new releases.

## Installation

Requirements:

To install:

```console
> pub global activate -sgit https://github.com/holyspidoo/GitRel
```

To update, run activate again:

```console
> pub global activate -sgit https://github.com/holyspidoo/GitRel
```

## Usage

To run GitRel, you either specify a github username as argument, or you create a `repos.txt` file and run GitRel in the same directory as repos.txt
```
GitRel [-d] [username]
```

If the github username has starred repos, everyone will be checked for new releases. Every repo URL in `repos.txt` will also be checked for new releases.
The format of `repos.txt` is **one** URL per line.

Example of repos.txt:
```
https://github.com/acidanthera/WhateverGreen
https://github.com/acidanthera/Lilu
```

Running `GitRel` in the same directory as that `repos.txt` file will result in:

```
Processing Repos from file repos.txt
-------------------------------------------------------
WhateverGreen, 1.2.3
Last update: 	about a month ago
-------------------------------------------------------
Lilu, 1.2.7
Last update: 	about a month ago

```

The `-d` flag creates a file called `updateDates.json` where it stores the release dates. 
Next time you run the tool with `-d` again, it will be able to tell you if new releases 
appeared since the last time you checked. Yeah, this is a pretty niche edge case 🙂.
Just be careful since the dates file is created in the directory where you run `GitRel -d`.

## Issues and bugs

Please file reports on the
[GitHub Issue Tracker](https://github.com/holyspidoo/GitRel/issues).
