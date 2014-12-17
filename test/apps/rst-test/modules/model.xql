xquery version "3.0";

import module namespace json="http://www.json.org";
import module namespace rst="http://lagua.nl/lib/rst";

(: all params are passed from the controller :)

rst:process(request:get-parameter("path",""),map {
	"module-uri" := request:get-parameter("module-uri",""),
	"module-prefix" := request:get-parameter("module-prefix",""),
	"module-location" := request:get-parameter("module-location",""),
	"root-collection" := request:get-parameter("root-collection",""),
	"id-property" := request:get-parameter("id-property","id")
})