# nbt parser

A [Named Binary Tag (nbt)](https://minecraft.fandom.com/wiki/NBT_format) command line tool for macos / linux.
This tool allows reading nbt files and outputing to xml for manual editing. When editing is completed the file can be converted back to .nbt format.

## Installation

Download the executable from the releases tab, or compile with `shards build --release`

## Usage

#### Show usage and help

```sh
nbt --help
```

### Converting files

- File format will be detected by the extension of the input and output arguments.
- Use `-f` to specify the output format
- Output will be to standard out (stdout) unless `-o` is specified.

#### Convert an nbt file to xml

```sh
nbt -i input.dat -o output.xml
```

#### Convert an xml file to nbt

```sh
nbt -i input.xml -o output.dat
```

## Development

Make sure tests are passing `crystal spec` and submit a PR.

## Contributing

1. Fork it (<https://github.com/sleepinginsomniac/nbt_parser/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alex Clink](https://github.com/sleepinginsomniac)
