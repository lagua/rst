xquery version "3.0";

(:
 * This module provides RQL parsing and querying. For example:
 * var parsed = require("./parser").parse("b=3&le(c,5)");
 :)

module namespace rst="http://lagua.nl/lib/rst";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

(:  the main function to call from a controller :)
declare function rst:request($path,$functions) {
	let $params := tokenize($path, "/")
	let $model := $params[1]
	let $params := remove($params,1)
    let $id := string-join($params,"/")
	let $method := request:get-method()
	let $qstr := request:get-query-string()
	let $content-type := request:get-header("content-type")
	let $accept := request:get-header("accept")
	
	return
		if($method = "GET") then
			if($qstr = "" and $id != "") then
				rst:get($model,$id,$functions)
			else 
				rst:query($qrstr,$functions)
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
					(:  bdeebdeebdatsallfolks :)
					$data
			return
				(: this launches a custom method :)
				if($method = "POST" and exists($data[method|function])) then
					rst:method($functions($data/*[name() = ("method","function")]/string(),$data))
};

declare function rst:method($fn,$data) {
	
};

declare function rst:to-plain-xml($node as element()) as element()* {
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