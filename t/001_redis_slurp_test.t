#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ebin/ -boot start_sasl

main(_) ->
  etap:plan(unknown),
  
  %% Devil Redis
  {ok, Pid} = redis:start_link([{port, 6660}]),

  %% Test flushdb first to ensure we have a clean db
  etap:is(
    redis:q(Pid, [flushdb]),
    {ok, <<"OK">>},
    "+ status reply"
  ),

  etap:is(
    redis:q(Pid, [foobar]),
    {error, <<"ERR unknown command 'FOOBAR'">>},
    "- status reply"
  ),

  etap:is(
    redis:q(Pid, [set, "foo", "bar"]),
    {ok, <<"OK">>},
    "test status reply"
  ),

  etap:is(
    redis:q(Pid, [get, "foo"]),
    {ok, <<"bar">>},
    "test bulk reply"
  ),

  etap:is(
    redis:q(Pid, [get, "notakey"]),
    {ok, undefined},
    "test bulk reply with -1 length"
  ),

  etap:is(
    redis:q(Pid, [keys, "notamatch"]),
    {ok, <<>>},
    "test bulk reply with 0 length"
  ),

  redis:q(Pid, [set, "abc", "123"]),
  etap:is(
    redis:q(Pid, [mget, "foo", "abc"]),
    [{ok, <<"bar">>}, {ok, <<"123">>}],
    "multi bulk reply"
  ),

  ok.
