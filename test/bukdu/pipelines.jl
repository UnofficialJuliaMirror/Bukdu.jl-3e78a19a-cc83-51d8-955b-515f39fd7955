module test_bukdu_pipelines

using Test # @test
using Bukdu # Plug.AbstractPlug ApplicationController Conn Routing pipeline plug routes get

struct CSRF <: Plug.AbstractPlug
end

function plug(::Type{CSRF}, c::C) where {C<:ApplicationController}
    c.params[:csrf] = "1"
end

struct Auth <: Plug.AbstractPlug
end

function plug(::Type{Auth}, c::C) where {C<:ApplicationController}
    c.params[:auth] = "1"
end

pipeline(:web, :auth) do c
    plug(CSRF, c)
end

pipeline(:auth) do c
    plug(Auth, c)
end

struct W <: ApplicationController; conn::Conn end
struct A <: ApplicationController; conn::Conn end
index(w::W) = keys(w.params)
index(a::A) = keys(a.params)

routes(:web) do
    get("/w", W, index)    
end

routes(:auth) do
    get("/a", A, index)    
end

@test Router.request(get, "/a") == ["csrf", "auth"]
@test Router.request(get, "/w") == ["csrf"]

@test Utils.read_stdout(CLI.routes) == """
GET  /w  W  index  :web
GET  /a  A  index  :auth"""

Routing.empty!()

end # module test_bukdu_pipelines