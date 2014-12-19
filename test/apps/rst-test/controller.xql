xquery version "3.0";

import module namespace rst="http://lagua.nl/lib/rst";
import module namespace config="http://lagua.nl/apps/rst-test/config" at "modules/config.xqm";
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if(starts-with($exist:path,"/model")) then
    let $seq := subsequence(tokenize($exist:path,"/"), 2)
    let $path := string-join($seq,"/")
    let $loggedIn := login:set-user("org.exist.login", (), false())
    (: import params from config :)
    return rst:process($path,$config:crud-params)
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
