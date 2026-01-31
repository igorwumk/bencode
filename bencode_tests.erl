-module(bencode_tests).
-include_lib("eunit/include/eunit.hrl").

integer_test_() -> 
    [
        ?_test(?assertEqual(123, bencode:parse_all(<<"i123e">>))),
        ?_test(?assertEqual(-42, bencode:parse_all(<<"i-42e">>))),
        ?_test(?assertEqual({error, {parse, invalid_number}}, bencode:parse_all(<<"i123">>))),
        ?_test(?assertEqual({error, {parse, invalid_number}}, bencode:parse_all(<<"i01e">>))),
        ?_test(?assertEqual({error, {parse, invalid_number}}, bencode:parse_all(<<"i-0e">>)))
    ].

string_test_() -> 
    [
        ?_test(?assertEqual(<<"spam">>, bencode:parse_all(<<"4:spam">>))),
        ?_test(?assertEqual({error, trailing_data}, bencode:parse_all(<<"4:spamJUNK">>)))
    ].
