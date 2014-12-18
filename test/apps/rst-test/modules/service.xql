xquery version "3.0";

module namespace service="http://lagua.nl/rst-test/services/simple";

declare function service:get($collection as xs:anyURI,$id as xs:string, $directives as map) {
	doc($collection || "/" || $id || ".xml")
};

declare function service:query($collection as xs:anyURI, $query-string as xs:string, $directives as map) {
	(: just return the collection in this example :)
	collection($collection)
};

declare function service:put($collection as xs:anyURI,$data as node(), $directives as map) {
	(: just use 'id' as primary key: this is also the key in $directives :)
	let $id := $data/id/string()
	let $id :=
		if($id) then
			$id
		else
			util:uuid()
	let $data := 
		element { name($data) } {
			$data/@*,
			element id { $id },
			$data/*[name() ne "id"]
		}
	return xmldb:store($collection,$id || ".xml", $data) 
};

declare function service:delete($collection as xs:anyURI, $id as xs:string) {
	xmldb:remove($collection, $id || ".xml")
};