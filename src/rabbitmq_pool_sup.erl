%%%-------------------------------------------------------------------
%% @doc rabbitmq_pool top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_pool_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).
-compile(export_all).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: #{id => Id, start => {M, F, A}}
%% Optional keys are restart, shutdown, type, modules.
%% Before OTP 18 tuples must be used to specify a child. e.g.
%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
		ProducerSpecs = producer_specs(),
		ConsumerSpecs = consumer_specs(),
    {ok, {{one_for_one, 10000, 1}, ProducerSpecs ++ ConsumerSpecs}}.

%%====================================================================
%% Internal functions
%%====================================================================


producer_specs()	->
		%%{ok, App} = application:get_application(?MODULE),
		App = rabbitmq_pool,
		ProducerServices = get_services(App, producer_services),
		[producer_spec(App, ProducerService) || ProducerService <- ProducerServices].

producer_spec(App, Service)	->
		{ok, Opts} = application:get_env(App, Service),
    PoolArgs =
          [
           {name, {local, Service}},
           {worker_module, rabbitmq_pool_producer}
          ] ++ Opts,
    poolboy:child_spec(Service, PoolArgs, Opts).


consumer_specs()  ->
    %% {ok, App} = application:get_application(?MODULE),
		App = rabbitmq_pool,
    ConsumerServices = get_services(App, consumer_services),
    [consumer_spec(App, ConsumerService) || ConsumerService <- ConsumerServices].

consumer_spec(App, Service) ->
  {ok, Opts} = application:get_env(App, Service),
  PoolArgs = 
        [
         {name, {local, Service}},
         {worker_module, rabbitmq_pool_consumer}
        ] ++ Opts,
    poolboy:child_spec(Service, PoolArgs, Opts).

% consumer_specs()	->
% 		WorkSpecs = work_specs(),
% 		TopicSpecs = topic_specs(),
% 		RouterSpecs = router_specs(),
% 		SubSpecs = sub_specs(),
% 		WorkSpecs ++ TopicSpecs ++ RouterSpecs ++ SubSpecs.

% work_specs()	->
% 		{ok, App} = application:get_application(?MODULE),
% 		WorkServices = get_services(App, work_services),
% 		[work_spec(App, WorkService) || WorkService <- WorkServices].

% work_spec(App, Service)	->
% 		{ok, Opts} = application:get_env(App, Service),
%     PoolArgs = 
%           [
%            {name, {local, Service}},
%            {worker_module, rabbitmq_pool_work}
%           ] ++ Opts,
%     poolboy:child_spec(Service, PoolArgs, Opts).
		
% topic_specs()  ->  
%     {ok, App} = application:get_application(?MODULE),
%     TopicServices = get_services(App, topic_services),
%     [topic_spec(App, TopicService) || TopicService <- TopicServices].

% topic_spec(App, Service) ->
%     {ok, Opts} = application:get_env(App, Service),
%     PoolArgs =
%           [
%            {name, {local, Service}},
%            {worker_module, rabbitmq_pool_topic}
%           ] ++ Opts,
%     poolboy:child_spec(Service, PoolArgs, Opts).

% router_specs()  ->
%     {ok, App} = application:get_application(?MODULE),
%     RouterServices = get_services(App, router_services),
%     [router_spec(App, RouterService) || RouterService <- RouterServices].

% router_spec(App, Service) ->
%     {ok, Opts} = application:get_env(App, Service),
%     PoolArgs =
%           [
%            {name, {local, Service}},
%            {worker_module, rabbitmq_pool_router}
%           ] ++ Opts,
%     poolboy:child_spec(Service, PoolArgs, Opts).

% sub_specs()  ->
%     {ok, App} = application:get_application(?MODULE),
% 		SubServices = get_services(App, sub_services),
%     [sub_spec(App, SubService) || SubService <- SubServices].

% sub_spec(App, Service) ->
%     {ok, Opts} = application:get_env(App, Service),
%     PoolArgs =
%           [
%            {name, {local, Service}},
%            {worker_module, rabbitmq_pool_sub}
%           ] ++ Opts,
%     poolboy:child_spec(Service, PoolArgs, Opts).


get_services(App, ServiceMode)	->
		case application:get_env(App, ServiceMode) of
				undefined	->
						[];
				{ok, Services}	->
						Services
		end.
