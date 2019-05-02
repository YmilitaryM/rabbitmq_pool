%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      Copyright (C) 2019 ... All rights reserved.
%%      FileName rabbitmq_pool_consumer.erl
%%      Create   ：Jin <ymilitarym@163.com
%%      Date     : 2019-04-29
%%      Describle: 
%%      
%%      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(rabbitmq_pool_consumer).
-include_lib("amqp_client/include/amqp_client.hrl").
-record(rabbitmq_server, {server = undefined, channel = undefined}).


-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2]).
-export([handle_info/2,
         terminate/2, code_change/3]).

start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).


init(Args)	->
		UserName = proplists:get_value(user, Args, <<"guest">>),
		Password = proplists:get_value(password , Args, <<"guest">>),
		Host = proplists:get_value(host, Args, "127.0.0.1"),
		{ok, Connection} = amqp_connection:start(#amqp_params_network{username = UserName, password = Password, host = Host}),
		{ok, Channel} = amqp_connection:open_channel(Connection),
		Exchange = proplists:get_value(exchange, Args, <<"">>),
		RoutingKey = proplists:get_value(routing_key, Args, <<"">>),
		case proplists:get_value(type, Args, worker) of
				worker	->
						Queue = proplists:get_value(queue, Args),
						amqp_channel:call(Channel, #'queue.declare'{queue = Queue,
                                                durable = true});
				Type	->
						case Type of
								router	->
										ExchangeType = <<"direct">>;
								sub	->
										ExchangeType = <<"fanout">>;
								topic	->
										ExchangeType = <<"topic">>
						end,
						amqp_channel:call(Channel, #'exchange.declare'{exchange = Exchange, type = ExchangeType}),
						#'queue.declare_ok'{queue = Queue} =
							amqp_channel:call(Channel, #'queue.declare'{durable = true}),
						amqp_channel:call(Channel, #'queue.bind'{queue = Queue,
																										 exchange = Exchange,
																										 routing_key = RoutingKey})
		end,

		%amqp_channel:call(Channel, #'queue.declare'{queue = Queue,
    %                                            durable = true}),
		%
		amqp_channel:call(Channel, #'basic.qos'{prefetch_count = 1}),
		Work = #'basic.consume'{queue = Queue},
		amqp_channel:subscribe(Channel, Work, self()),
		{ok, #rabbitmq_server{server = Connection ,channel = Channel}}.


terminate(_Reason, #rabbitmq_server{server = Server} = State) ->
		Server = State#rabbitmq_server.server,
		amqp_connection:close(Server),
		{ok, State}.

handle_info(#'basic.consume_ok'{}, State)	->
		{noreply, State};
handle_info({#'basic.deliver'{delivery_tag = Tag}, #amqp_msg{payload = Payload}}, #rabbitmq_server{channel = Channel} = State)	->
		Dots = length([C || C <- binary_to_list(Payload), C == $.]),
		receive
		after
			Dots * 1000	->
				ok
		end,
	
		amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
		private_handle_data(Payload, State),
		{noreply, State};
handle_info(_Info, State)	->
		{noreply, State}.

handle_call(_Request, _From, State)	->
		{reply, ok, State}.

handle_cast(_Request, State)	->
		{noreply, State}.

code_change(_OldVersion, State, _Extra)	->
		{ok, State}.
	
private_handle_data(PayLoad, State)	->
		io:format("PayLoad:~p, State:~p~n", [PayLoad, State]).
