-module(bencode).
-export([parse/1, parse_all/1, parse_file/1, encode/1]).

%% API

parse(<<$i, _/binary>> = Bin) -> parse_int(Bin);
parse(<<$l, _/binary>> = Bin) -> parse_list(Bin);
parse(<<$d, _/binary>> = Bin) -> parse_dict(Bin);
parse(<<Digit, _/binary>> = Bin) when Digit >= $0, Digit =< $9 -> parse_string(Bin);
parse(<<>>) -> {error, unexpected_eof};
parse(_) -> {error, not_implemented}.

parse_all(Bin) ->
    case parse(Bin) of
        {error, Reason} -> {error, {parse, Reason}};
        {Value, <<>>} -> Value;
        {_Value, _Rest} -> {error, trailing_data}
    end.

parse_file(Filename) -> 
    case file:read_file(Filename) of
        {ok, Bin} ->
            parse_all(Bin);
        {error, Reason} ->
            {error, {file, Reason}}
    end.

%% Private functions

read_number(Bin, Terminator) ->
    read_number(Bin, Terminator, 0).

read_number(<<Digit, Rest/binary>>, Terminator, Acc) when Digit >= $0, Digit =< $9 ->
    NewAcc = Acc * 10 + (Digit - $0),
    read_number(Rest, Terminator, NewAcc);

read_number(<<Terminator, Rest/binary>>, Terminator, Acc) -> 
    {Acc, Rest};

read_number(_, _, _) -> 
    {error, invalid_number}.

parse_string(Bin) ->
    {Len, AfterColon} = read_string_length(Bin),
    <<Str:Len/binary, Rest/binary>> = AfterColon,
    {Str, Rest}.

read_string_length(Bin) -> 
    read_number(Bin, $:).
 
parse_int(<<$i, Bin/binary>>) -> 
    read_int(Bin).

read_int(<<$0, Digit, _/binary>>) when Digit >= $0, Digit =< $9 ->
    {error, invalid_number};

read_int(<<$-, $0, _/binary>>) ->
    {error, invalid_number};

read_int(<<$-, Rest/binary>>) -> 
    case read_number(Rest, $e) of
        {N, R} -> {-N, R};
        Error -> Error
    end;

read_int(Bin) -> 
    read_number(Bin, $e).

parse_list(<<$l, Rest/binary>>) ->
    read_list(Rest, []).

read_list(<<$e, Rest/binary>>, Acc) ->
    {lists:reverse(Acc), Rest};

read_list(<<>>, _) ->
    {error, unexpected_eof};

read_list(Bin, Acc) ->
    case parse(Bin) of
        {Value, Rest} when Value =/= error ->
            read_list(Rest, [Value | Acc]); %% Appending at list start is O(1), at list end is O(n)
        {error, not_implemented} -> 
            {error, invalid_token};
        {error, Reason} -> 
            {error, Reason}
    end.

parse_dict(<<$d, Rest/binary>>) ->
    %%read_dict(Rest, #{}).
    read_dict(Rest, #{}, none).

%% No dictionary ordering

read_dict(<<$e, Rest/binary>>, Acc) ->
    {Acc, Rest};

%% TODO: change body to similar of read_dict/3 or remove
read_dict(Bin, Acc) ->
    case parse(Bin) of
        {error, _} = Err -> Err;
        {Key, Rest1} when Key =/= error ->
            case parse(Rest1) of
                {error, _} = Err -> Err;
                {Value, Rest2} -> 
                    read_dict(Rest2, Acc#{Key => Value})
            end;
        _ -> {error, invalid_dict_key}
    end.

%% With dictionary ordering

read_dict(<<$e, Rest/binary>>, Acc, _PrevKey) -> 
    {Acc, Rest};

read_dict(Bin, Acc, PrevKey) ->
    case Bin of
        <<Digit, _/binary>> when Digit >= $0, Digit =< $9 ->
            {Key, Rest1} = parse_string(Bin),
            %% ordering check (lenient)
            _  = case PrevKey of
                none -> ok;
                _ when Key > PrevKey -> ok;
                _ -> out_of_order
            end,
            case parse(Rest1) of
                {error, not_implemented} ->
                    {error, invalid_token};
                {error, Reason} -> 
                    {error, Reason};
                {Value, Rest2} ->
                    read_dict(Rest2, Acc#{Key => Value}, Key)
            end;
        _ -> 
            {error, invalid_dict_key}
    end.

encode(Value) when is_integer(Value) -> encode_int(Value);
encode(Value) when is_binary(Value) -> encode_string(Value);
encode(Value) when is_list(Value) -> encode_list(Value);
encode(Value) when is_map(Value) -> encode_dict(Value);
encode(_) -> {error, input_not_supported}.

encode_int(Value) -> 
    BinaryInt = integer_to_binary(Value),
    <<"i", BinaryInt/binary, "e">>.
    

encode_string(Value) ->
    Size = byte_size(Value),
    SizeBin = integer_to_binary(Size),
    <<SizeBin/binary, ":", Value/binary>>.


encode_list(Value) -> 
    case encode_list(Value, <<>>) of
        {error, Reason} -> {error, Reason};
        ItemsBin -> <<"l", ItemsBin/binary, "e">>
    end.

encode_list([], Acc) -> Acc;
encode_list([H | T], Acc) ->
    case encode(H) of
        {error, Reason} -> {error, Reason};
        Bin when is_binary(Bin) -> encode_list(T, <<Acc/binary, Bin/binary>>)
    end.

encode_dict(Value) -> 
    Pairs = maps:to_list(Value),
    case encode_dict(sort_pairs(Pairs), <<>>) of
        {error, Reason} -> {error, Reason};
        ItemsBin -> <<"d", ItemsBin/binary, "e">>
    end.

sort_pairs(Pairs) -> lists:sort(fun({K1, _}, {K2, _}) -> K1 =< K2 end, Pairs).

encode_dict([], Acc) -> Acc;
encode_dict([{Key, Value} | T], Acc) ->
    case is_binary(Key) of
        false -> {error, input_not_supported};
        true -> 
            case encode_string(Key) of 
                {error, Reason} -> {error, Reason};
                KeyBin ->
                    case encode(Value) of
                        {error, Reason} -> {error, Reason};
                        ValBin -> encode_dict(T, <<Acc/binary, KeyBin/binary, ValBin/binary>>)
                    end
            end
    end.
