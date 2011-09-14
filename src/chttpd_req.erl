-module(chttpd_req, [Module, HttpReq, MochiReq]).

-export([path/0, absolute_uri/1]).
-export([get_header_value/1, get_primary_header_value/1, get/1, dump/0]).
-export([send/1, recv/1, recv/2, recv_body/0, recv_body/1, stream_body/3]).
-export([start_response/1, start_response_length/1, start_raw_response/1]).
-export([respond/1, ok/1]).
-export([not_found/0, not_found/1]).
-export([parse_post/0, parse_qs/0]).
-export([should_close/0, cleanup/0]).
-export([parse_cookie/0, get_cookie_value/1]).
-export([serve_file/2, serve_file/3]).
-export([accepted_encodings/1]).
-export([accepts_content_type/1]).

path() ->
    Module:get_path(HttpReq).

absolute_uri(Path) ->
    XHost = couch_config:get("httpd", "x_forwarded_host", "X-Forwarded-Host"),
    Host = case MochiReq:get_header_value(XHost) of
        undefined ->
            case MochiReq:get_header_value("Host") of
                undefined ->
                    {ok, {Address, Port}} = inet:sockname(MochiReq:get(socket)),
                    inet_parse:ntoa(Address) ++ ":" ++ integer_to_list(Port);
                Value1 ->
                    Value1
            end;
        Value -> Value
    end,
    XSsl = couch_config:get("httpd", "x_forwarded_ssl", "X-Forwarded-Ssl"),
    Scheme = case MochiReq:get_header_value(XSsl) of
        "on" -> "https";
        _ ->
            XProto = couch_config:get("httpd", "x_forwarded_proto",
                "X-Forwarded-Proto"),
            case MochiReq:get_header_value(XProto) of
                % Restrict to "https" and "http" schemes only
                "https" -> "https";
                _ -> "http"
            end
    end,
    Module:build_uri(HttpReq, Scheme, Host, Path).

get_header_value(K) -> MochiReq:get_header_value(K).
get_primary_header_value(K) -> MochiReq:get_primary_header_value(K).
get(K) -> MochiReq:get(K).
dump() -> MochiReq:dump().

send(Data) -> MochiReq:send(Data).
recv(Length) -> MochiReq:recv(Length).
recv(Length, Timeout) -> MochiReq:recv(Length, Timeout).
recv_body() -> MochiReq:recv_body().
recv_body(MaxBody) -> MochiReq:recv_body(MaxBody).
stream_body(Size, Fun, State) -> MochiReq:stream_body(Size, Fun, State).

start_response({Code, RespHdrs}) ->
    MochiReq:start_response({Code, set_headers(RespHdrs)}).

start_response_length({Code, RespHdrs, Length}) ->
    MochiReq:start_response_length({Code, set_headers(RespHdrs), Length}).

start_raw_response({Code, RespHdrs}) ->
    MochiReq:start_raw_length({Code, set_headers(RespHdrs)}).

respond({Code, RespHdrs, Body}) ->
    MochiReq:respond({Code, set_headers(RespHdrs), Body}).

ok({CType, RespHdrs, Body}) ->
    MochiReq:ok({CType, set_headers(RespHdrs), Body});
ok(Info) ->
    MochiReq:ok(Info).

not_found() -> MochiReq:not_found().
not_found(Headers) -> MochiReq:not_found(Headers).

should_close() -> MochiReq:should_close().
cleanup() -> MochiReq:cleanup().

parse_qs() -> MochiReq:parse_qs().
parse_post() -> MochiReq:parse_post().

parse_cookie() -> MochiReq:parse_cookie().
get_cookie_value(Key) -> MochiReq:get_cookie_value(Key).

serve_file(Path, Root) -> MochiReq:serve_file(Path, Root).
serve_file(Path, Root, Headers) -> MochiReq:serve_file(Path, Root, Headers).

accepted_encodings(Supported) -> MochiReq:accepted_encodings(Supported).
accepts_content_type(CType) -> MochiReq:accepts_content_type(CType).

set_headers(RespHdrs) ->
    DefaultHeaders = Module:default_headers(HttpReq),
    set_default_headers(DefaultHeaders, RespHdrs).

set_default_headers([], Headers) ->
    Headers;
set_default_headers([{Key, Val} | Rest], Headers) ->
    NewHeaders =
    case couch_util:get_value(Key, Headers) of
        undefined -> Headers ++ [{Key, Val}];
        _ -> Headers
    end,
    set_default_headers(Rest, NewHeaders).

