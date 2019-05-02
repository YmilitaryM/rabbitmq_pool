rabbitmq_pool
=====

An OTP application

Build
-----

    $ rebar3 compile

Shell
-----
	worker model
		rabbitmq_pool_producer:work(producer_test, <<"test">>, <<"hello worker">>).
		rabbitmq_pool_producer:work(Server, Queue, PayLoad).
	topic model
		rabbitmq_pool_producer:topic(producer_test, <<"topic_exchange_test">>, <<"topic_routing_key_test">>, <<"hello topic">>).
		rabbitmq_pool_producer:topic(Server, Exchange, RoutingKey, PayLoad).
	router model
		rabbitmq_pool_producer:route(producer_test, <<"router_exchange_test">>, <<"router_routing_key_test">>, <<"hello router">>).
		rabbitmq_pool_producer:route(Server, Exchange, RoutingKey, PayLoad).
	sub model
		rabbitmq_pool_producer:sub(producer_test, <<"sub_exchange_test">>, <<"sub_routing_key_test">>, <<"hello sub">>).
		rabbitmq_pool_producer:sub(Server, Exchange, RoutingKey, PayLoad).

