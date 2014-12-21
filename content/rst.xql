xquery version "3.0";

(:
 * This module provides an interface that normalizes to Dojo/Persevere-style REST functions
 * Currently this modules forces JSON output
 :)

module namespace rst="http://lagua.nl/lib/rst";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
import module namespace json="http://www.json.org";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

(:  the main function to call from the controller :)
declare function rst:process($path as xs:string, $params as map) {
	let $query := map { "string" := string(request:get-query-string()) }
	return rst:process($path, $params, $query)
};

(:  function to call from the controller, override query :)
declare function rst:process($path as xs:string, $params as map, $query as map) {
	let $params := map:new(($params, map { "from-controller" := true() }))
	let $method := request:get-method()
	let $content-type := string(request:get-header("content-type"))
	let $accept := string(request:get-header("accept"))
	let $data :=
		if($method = ("PUT","POST")) then
			string(request:get-data())
		else
			()
	return rst:process($path, $params, $query, $content-type, $accept, $data, $method)
};

(:  the main function to call from RESTXQ :)
declare function rst:process($path as xs:string, $params as map, $query as map, $content-type as xs:string, $accept as xs:string, $data as item()*, $method as xs:string) {
	let $model := replace($path, "^/?([^/]+).*", "$1")
	let $id := replace($path, "^/?" || $model || "/(.*)", "$1")
	let $root := $params("root-collection")
	(: TODO choose default root :)
	let $collection := $root || "/" || $model
	let $response :=
		if($method = "GET") then
			if($id) then
				rst:get($collection,$id,$params)
			else 
				rst:query($collection,$query,$params)
		else if($method=("PUT","POST")) then
			(: assume data :)
			let $data := 
				if(matches($content-type,"application/[json|javascript]")) then
					if($data) then
						rst:to-plain-xml(xqjson:parse-json(util:binary-to-string($data)))
					else
						<root/>
				else
					(:  bdee bdee bdatsallfolks :)
					$data
			return
				(: this launches a custom method :)
				if($method = "POST" and exists($data[method|function])) then
					rst:custom($collection,$id,$data,$params)
				else
					rst:put($collection,$data,$params)
		else if($method = "DELETE") then
			rst:delete($collection,$id,$params)
		else
			<http:response status="405" message="Method not implemented"/>
	let $output := (
	    util:declare-option("output:method", "json"),
        util:declare-option("output:media-type", "application/json")
	)
	return
		if(name($response[1]) = "http:response") then
			(: expect custom response :)
			if($params("from-controller")) then
			    (: parse http:response entry :)
			    (
    			    if($response[1]/@status) then
    			        response:set-status-code($response[1]/@status)
    			    else
    			        (),
    			    for $header in $response[1]/http:header return 
    			        response:set-header($header/@name,$header/@value)
    			    ,
    		        remove($response,1)
		        )
            else
                (<rest:response>{$response[1]}</rest:response>,
                remove($response,1))
        else
	        $response
};

declare function rst:get($collection as xs:string,$id as xs:string,$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":get"), 3)
	return $fn($collection,$id,$params)
};

declare function rst:query($collection as xs:string,$query as map,$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":query"), 3)
	return $fn($collection,$query,$params)
};

declare function rst:put($collection as xs:string,$data as node(),$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":put"), 3)
	return $fn($collection,$data,$params)
};

declare function rst:delete($collection as xs:string,$id as xs:string,$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":delete"), 3)
	return $fn($collection,$id,$params)
};

declare function rst:custom($collection as xs:string,$id as xs:string,$data as node(),$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":" || $data/*[name() = ("method","function")]), 4)
	return $fn($collection,$id,$data,$params)
};

declare function rst:import-module($params as map) {
	let $uri := xs:anyURI($params("module-uri"))
	let $prefix := $params("module-prefix")
	let $location := xs:anyURI($params("module-location"))
	return util:import-module($uri, $prefix, $location)
};

declare %private function rst:to-plain-xml($node as element()) as element()* {
	let $name := string(node-name($node))
	let $name :=
		if($name = "json") then
			"root"
		else if($name = "pair" and $node/@name) then
			$node/@name
		else
			$name
	return
		if($node[@type = "array"]) then
			for $item in $node/node() return
				let $item := element {$name} {
					attribute {"json:array"} {"true"},
						$item/node()
					}
					return rst:to-plain-xml($item)
		else
			element {$name} {
				if($node/@type = ("number","boolean")) then
					attribute {"json:literal"} {"true"}
				else
					(),
				$node/@*[matches(name(.),"json:")],
				for $child in $node/node() return
					if($child instance of element()) then
						rst:to-plain-xml($child)
					else
						$child
			}
};