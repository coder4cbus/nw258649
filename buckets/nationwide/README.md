# Scoop Nationwide

> A Nationwide-specific [bucket](https://github.com/lukesampson/scoop/wiki/Buckets) for [Scoop](https://scoop.sh).

## Installation

Add this bucket via the command-line:

```powershell
scoop bucket add "nationwide" "https://github.nwie.net/Nationwide/scoop-nationwide.git"
```

## Usage

Once added, this bucket's [apps](https://github.com/lukesampson/scoop/wiki/Apps) can be installed via the command-line with the following syntax, where `<app>` is the identifier of the desired app:

```powershell
scoop install <app>
```

To install app [aws-federator](./bucket/aws-federator.json), for example, run the following:

```powershell
scoop install "aws-federator"
```

See [bucket](./bucket) directory for all of this bucket's available apps and Scoop's [commands](https://github.com/lukesampson/scoop/wiki/Commands) documentation for all available Scoop commands.
