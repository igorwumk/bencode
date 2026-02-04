-module(bencode_tests).
-include_lib("eunit/include/eunit.hrl").

integer_test_() -> 
    [
        ?_test(?assertEqual(123, bencode:parse_all(<<"i123e">>))),
        ?_test(?assertEqual(-42, bencode:parse_all(<<"i-42e">>)))
    ].

integer_no_terminator_test_() ->
    [
        ?_test(?assertEqual({error, {parse, invalid_number}}, bencode:parse_all(<<"i123">>)))
    ].

integer_leading_zero_test_() ->
    [
        ?_test(?assertEqual({error, {parse, invalid_number}}, bencode:parse_all(<<"i01e">>)))
    ].

integer_negative_zero_test_() ->
    [
        ?_test(?assertEqual({error, {parse, invalid_number}}, bencode:parse_all(<<"i-0e">>)))
    ].

string_test_() -> 
    [
        ?_test(?assertEqual(<<"spam">>, bencode:parse_all(<<"4:spam">>)))
    ].

string_trailing_data_test_() -> 
    [
        ?_test(?assertEqual({error, trailing_data}, bencode:parse_all(<<"4:spamJUNK">>)))
    ].

list_test_() ->
    [
        ?_test(?assertEqual([], bencode:parse_all(<<"le">>))),
        ?_test(?assertEqual([<<"spam">>], bencode:parse_all(<<"l4:spame">>))),
        ?_test(?assertEqual([1, 2, 3], bencode:parse_all(<<"li1ei2ei3ee">>)))
    ].

list_mixed_test_() ->
    [
        ?_test(?assertEqual([<<"spam">>, 42, <<"eggs">>], bencode:parse_all(<<"l4:spami42e4:eggse">>)))
    ].

list_nested_test_() ->
    [
        ?_test(?assertEqual([[<<"abc">>], -1, <<"e">>], bencode:parse_all(<<"ll3:abcei-1e1:ee">>)))
    ].

list_error_test_() ->
    [
        ?_test(?assertEqual({error, {parse, unexpected_eof}}, bencode:parse_all(<<"li1ei2e">>)))
    ].

list_invalid_item_test_() ->
    [
        ?_test(?assertEqual({error, {parse, invalid_token}}, bencode:parse_all(<<"l4:spamXe">>)))
    ].

dict_empty_test_() ->
    [
        ?_test(?assertEqual(#{}, bencode:parse_all(<<"de">>)))
    ].

dict_single_test_() ->
    [
        ?_test(?assertEqual(#{<<"cow">> => <<"moo">>}, bencode:parse_all(<<"d3:cow3:mooe">>)))
    ].

dict_multi_test_() ->
    [
        ?_test(?assertEqual(#{<<"cow">> => <<"moo">>, <<"spam">> => <<"eggs">>}, bencode:parse_all(<<"d3:cow3:moo4:spam4:eggse">>)))
    ].

dict_nested_test_() ->
    [
        ?_test(?assertEqual(#{<<"list">> => [1, 2]}, bencode:parse_all(<<"d4:listli1ei2eee">>)))
    ].

dict_invalid_key_test_() -> 
    [
        ?_test(?assertEqual({error, {parse, invalid_dict_key}}, bencode:parse_all(<<"di1e3:fooe">>)))
    ].

dict_unexpected_eof_test_() ->
    [
        ?_test(?assertEqual({error, {parse, unexpected_eof}}, bencode:parse_all(<<"d3:key">>)))
    ].

dict_invalid_token_test_() ->
    [
        ?_test(?assertEqual({error, {parse, invalid_token}}, bencode:parse_all(<<"d3:keyXe">>)))
    ].
