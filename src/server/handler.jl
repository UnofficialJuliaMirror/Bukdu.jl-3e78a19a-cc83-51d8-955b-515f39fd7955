# module Bukdu

module Server

import HttpCommon: Request, Response, parsequerystring
import URIParser: unescape_form
import ....Bukdu
import Bukdu: Routing
import Bukdu: ApplicationEndpoint, Endpoint, Router, Conn
import Bukdu: before, after, post, plug
import Bukdu: conn_no_content, conn_not_found
import Bukdu: Logger

include("form_data.jl")

const commit_short = string(LibGit2.revparseid(LibGit2.GitRepo(Pkg.dir("Bukdu")), "HEAD"))[1:7]
const info = "Bukdu (commit $commit_short with Julia $VERSION"

function handler{AE<:ApplicationEndpoint}(::Type{AE}, req::Request, res::Response)
    if AE==Endpoint && !haskey(Routing.endpoint_routes, AE)
        Endpoint() do
            plug(Router)
        end
    end
    routes = Routing.endpoint_routes[AE]
    if method_exists(before, (Request,Response))
        before(req, res)
    end
    verb = getfield(Bukdu, Symbol(lowercase(req.method)))
    local conn::Conn
    try
        data = post==verb ? post_form_data(req) : Assoc()
        conn = Routing.request(Nullable{Type{AE}}(AE), routes, verb, req.resource, Assoc(req.headers), data) do route
            Base.function_name(route.verb) == Base.function_name(verb)
        end
    catch ex
        stackframes = stacktrace(catch_backtrace())
        if !isa(ex, Bukdu.NoRouteError)
            Logger.error() do
                Logger.verb_uppercase(verb), req.resource, ex, stackframes
            end
        end
        conn = conn_not_found(verb, req.resource, ex, stackframes)
    end
    for (key,value) in conn.resp_headers
        res.headers[key] = value
    end
    res.headers["Server"] = Server.info
    res.status = conn.status
    if isa(conn.resp_body, Vector{UInt8}) || isa(conn.resp_body, String)
        res.data = conn.resp_body
    else
        res.data = string(conn.resp_body)
    end
    if method_exists(after, (Request,Response))
        after(req, res)
    end
    res
end

end # module Bukdu.Server
