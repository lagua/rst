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

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

(:  the main function to call from a controller :)
declare function rst:process($path as xs:string, $params as map) {
	let $model := replace($path, "^/*([^/]+)/.*", "$1")
	let $id := replace($path, "^/*[^/]+(.*)", "$1")
	let $method := request:get-method()
	let $query-string := string(request:get-query-string())
	let $content-type := request:get-header("content-type")
	let $accept := request:get-header("accept")
	let $root := $params("root-collection")
	(: TODO choose default root :)
	let $collection := xs:anyURI($root || "/" || $model)
	return
		if($method = "GET") then
			if($query-string = "" and $id != "") then
				rst:get($collection,$id,$params)
			else 
				rst:query($collection,$query-string,$params)
		else if($method=("PUT","POST")) then
			(: assume data :)
			let $data := request:get-data()
			let $data := 
				if(matches($content-type,"application/[json|javascript]")) then
					let $data :=
						if(string($data) != "") then
							$data
						else
							"{}"
					return rst:to-plain-xml(xqjson:parse-json($data))
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
			(: json-friendly error :)
			(
				response:set-status-code(405),
				<json:value>Error: Method not implemented</json:value>
			)
};

declare function rst:get($collection as xs:anyURI,$id as xs:string,$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":get"), 3)
	return $fn($collection,$id,$params)
};

declare function rst:query($collection as xs:anyURI,$query-string as xs:string,$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":query"), 3)
	return $fn($collection,$query-string,$params)
};

declare function rst:put($collection as xs:anyURI,$data as node(),$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":put"), 3)
	return $fn($collection,$data,$params)
};

declare function rst:delete($collection as xs:anyURI,$id as xs:string,$params as map) {
	let $module := rst:import-module($params)
	let $fn := function-lookup(xs:QName($params("module-prefix") || ":delete"), 3)
	return $fn($collection,$id,$params)
};

declare function rst:custom($collection as xs:anyURI,$id as xs:string,$data as node(),$params as map) {
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