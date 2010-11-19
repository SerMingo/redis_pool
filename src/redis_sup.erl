%% Copyright (c) 2010 Valentino Volonghi <valentino@adroll.com>
%% 
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%% 
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
-module(redis_sup).
-behaviour(supervisor).

%% Supervisor callbacks
-export([add_pool/1, add_pool/2, add_pool/3, add_pool/5, remove_pool/1]).
-export([init/1, start_link/0]).

cycle_if_needed(_Name, Opts, Opts) ->
    ok;
cycle_if_needed(Name, _Opts, NewOpts) ->
    redis_pool:cycle(Name, NewOpts).

add_pool(Size) ->
    add_pool(redis_pool, [], 600, 60000, Size).
add_pool(Name, Size) ->
    add_pool(Name, [], 600, 60000, Size).
add_pool(Name, Opts, Size) ->
    add_pool(Name, Opts, 600, 60000, Size).
add_pool(Name, Opts, MaxRestarts, Interval, Size) ->
    case redis_pool:pid(Name) of
        {error, {not_found, Name}} ->
            {ok, _} = supervisor:start_child(?MODULE, [Name, Opts, MaxRestarts, Interval]);
        _ ->
            cycle_if_needed(Name, redis_pool:info(Name, opts), Opts)
    end,
    redis_pool:expand(Name, Size).

remove_pool(Name) ->
    case redis_pool:pid(Name) of
        {error, {not_found, Name}} ->
            ok;
        _ ->
            redis_pool:stop(Name)
    end.

start_link() ->
    supervisor:start_link({local, ?MODULE}, redis_sup, []).

init([]) ->
    Pool = {undefined, {redis_pool, start_link, []},
                transient, 10000, worker, [redis_pool]},
    
    {ok, {{simple_one_for_one, 100000, 1},
        [Pool]
      }}.
