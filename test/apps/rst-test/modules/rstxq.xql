xquery version "3.0";

module namespace rstxq="http://lagua.nl/apps/rst-test/rstxq";

import module namespace json="http://www.json.org";
import module namespace req="http://exquery.org/ns/request";
import module namespace rst="http://lagua.nl/lib/rst";
import module namespace config="http://lagua.nl/apps/rst-test/config" at "config.xqm";

declare
    %rest:GET
    %rest:POST
    %rest:PUT
    %rest:DELETE
    %rest:path("/model")
function rstxq:get($body) {
    (: import params from config :)
    rst:process(replace(rest:uri(),"^[exist/]+restxq/(.*)","$1"), $config:crud-params, string(req:query()), req:method(), $body, req:header("content-type"), req:header("accept"))
};