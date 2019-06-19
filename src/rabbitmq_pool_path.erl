%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      Copyright (C) 2019 ... All rights reserved.
%%      FileName ：rabbitmq_pool_path.erl
%%      Create   ：Jin <ymilitarym@163.com
%%      Date     : 2019-06-19
%%      Describle: 
%%      
%%      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(rabbitmq_pool_path).
-behaviour(gen_server).
-export([start_link/1, init/1]).
-export([handle_call/3,
		 handle_info/2,
		 handle_cast/2,
		 terminate/2,
		 code_change/3]).
-export([get_pid/1, get_service_pid/1,
		 register/2]).

start_link(Args)	->
	gen_server:start_link(?MODULE, Args, []).

init(Args)	->
	% EtsName = proplists:get_value(ets_name, Args),
	io:format("Args:~p~n", [Args]),
	ets:new(Args, [set, private, named_table, {read_concurrency, true}]),
	{ok, #{ets_name => Args}}.

handle_call(get_pid, _From, #{ets_name := EtsName} = State)	->
	TuplePids = ets:tab2list(EtsName),
	Reply = [Pid || {_, Pid} <- TuplePids],
	{reply, Reply, State};

handle_call(_Msg, _From, State)	->
	{reply, ok, State}.

handle_cast({register, Pid}, #{ets_name := EtsName} = State)	->
	MillSeconds = erlang:system_time(milli_seconds),
	Res = ets:insert(EtsName, {MillSeconds, Pid}),
	io:format("Res:~p~n", [Res]),
	{noreply, State};
handle_cast(_Other, State)	->
	{noreply, State}.

handle_info(_Msg, State)	->
	{noreply, State}.

terminate(_Reason, _State)	->
	ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

get_pid(Service)	->
	ServicePid = get_service_pid(Service),
	gen_server:call(ServicePid, get_pid).

register(Service, Pid)	->
	ServicePid = get_service_pid(Service),
	gen_server:cast(ServicePid, {register, Pid}).

get_service_pid(Service)	->
	ServiceName = list_to_atom("path_service_" ++ atom_to_list(Service)),
	cuesport:get_worker(ServiceName).

