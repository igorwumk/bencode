A simple bencode parser made in Erlang.

## Functionality

- All bencode data types decoded into Erlang data types
- Bencode strings kept as binary strings
- Bencode dictionaries decoded into Erlang maps
- Error-checking

## API

- `parse/1` - accepts bencode-encoded binary stream, outputs the appropriate Erlang term relating to the single bencode data type consumed or `{error, Reason}` if fails
- `parse_all/1` - accepts bencode-encoded binary stream, outputs the appropriate Erlang term relating to the bencode data, `{error, {parse, Reason}}` if fails at parsing or `{error, trailing_data}` if excessive data present in stream
- `parse_file/1` - accepts filename of a file with bencode binary stream to be parsed, outputs the Erlang term, errors from `parse_all/1` or `{error, {file, Reason}}` if file load fails
  
