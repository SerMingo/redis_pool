#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ebin/ -boot start_sasl

main(_) ->
  etap:plan(unknown),
    
  %% Redis anonymous connection
  {ok, Pid} = redis:start_link([{port, 6660}]),
  etap:ok(is_pid(Pid), "redis:connect/1 returns a pid"),
  
  %% Redis named connection
  etap:is(redis:start_link(conn, [{port, 6660}]), ok, "redis:connect/2 returns ok"),
  
  %% flushdb
  etap:is(redis:flushdb(Pid), {ok, <<"OK">>}, "flushdb command returns ok"),
  etap:is(redis:flushdb(conn), {ok, <<"OK">>}, "flushdb command returns ok"),

  %% set
  etap:is(redis:set(Pid, "foo", "bar"), {ok, <<"OK">>}, "set command returns ok"),
  etap:is(redis:set(conn, "foo1", "bar"), {ok, <<"OK">>}, "set command returns ok"),

  %% get
  etap:is(redis:get(Pid, "foo"), {ok, <<"bar">>}, "get command returns correct result"),
  etap:is(redis:get(conn, "foo1"), {ok, <<"bar">>}, "get command returns correct result"),

  %% get non-existent key
  etap:is(redis:get(Pid, "notakey"), {ok, undefined}, "get command for non-existent key returns correct result"),
  etap:is(redis:get(conn, "notakey"), {ok, undefined}, "get command for non-existent key returns correct result"),

  %% keys
  etap:is(redis:keys(Pid, "notamatch"), [<<>>], "keys command returns correct result"),
  etap:is(redis:keys(conn, "notamatch"), [<<>>], "keys command returns correct result"),

  etap:is(redis:keys(Pid, "*"), [<<"foo">>, <<"foo1">>], "keys command returns correct result"),
  etap:is(redis:keys(conn, "*"), [<<"foo">>, <<"foo1">>], "keys command returns correct result"),
  
  %% mget
  etap:is(redis:mget(Pid, ["foo", "foo1"]), [{ok, <<"bar">>}, {ok, <<"bar">>}], "mget command returns correct result"),

  %% sadd
  etap:is(redis:sadd(Pid, "bar", "a"), {ok, 1}, "sadd command returns correct result"),
  etap:is(redis:sadd(Pid, "bar", "b"), {ok, 1}, "sadd command returns correct result"),
  etap:is(redis:sadd(Pid, "bar", "c"), {ok, 1}, "sadd command returns correct result"),

  %% smembers
  etap:is(redis:smembers(Pid, "bar"), [{ok,<<"c">>},{ok,<<"a">>},{ok,<<"b">>}], "smembers command returns correct result"),
    
  %% incr
  etap:is(redis:incr(Pid, "counter"), {ok, 1}, "incr command returns correct result"),
  etap:is(redis:get(Pid, "counter"), {ok, <<"1">>}, "get command returns correct result"),
  
  ok.
