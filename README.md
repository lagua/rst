RST
===

CRUD and JSON-RPC mask for REST written in Xquery

To install in eXist-db:
--------------------

Download and install eXist-db 2.2 at http://exist-db.org

Build the package and install into eXist using the manager in the dashboard.

--------

RST abstracts from HTTP methods and content negotiation as to provide a standard architecture (best practices) for REST functionality. It implements the following patterns:

* Model: A target path (from a REST perspective) is considered to be /path/to/collection
* Identity: The entire path following the collection is considered to be an id, and may contain slashes. 
This departs from some other concepts, where path fragments are used to denote subsets of the data-model, 
specific functionality on the data-set or related data.
* CRUD: A standard set of functions to request and modify data: get, query, put, and delete.
* JSON-RPC: contents may be posted that triggers custom functionality, either on a specific resource or the entire collection. It can be seen as a simplified XML-RPC.

Note that this library doesn't perform any actions itself, but merely provides an intermediary layer between your app and a library that takes care of the actual database manipulation.

The core functions perform the following actions:

* `get` retrieves a resource by its id.
* `query` retrieves the entire collection of resources, that may then be filtered, sorted and paged.
* `put` creates or updates a resource. The resource may or may not already exist. 
An optional parameter defines the primary identifier for storing the resource. 
If that is not specified, the id may be auto-generated. The created/updated resource should be returned.
* `delete` deletes the resources with the given identifier from the collection.

An example CRUD library module that will be used by RST could be this:

```xquery
xquery version "3.0";

declare module namespace service="http://my/services/simple";

declare function service:get($collection as xs:string,$id as xs:string, $directives as map) {
	doc($collection || "/" || $id || ".xml")
};

declare function service:query($collection as xs:string, $query as item()*, $directives as map) {
	(: just return the collection in this example :)
	collection($collection)
};

declare function service:put($collection as xs:string,$data as node(), $directives as map) {
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

declare function service:delete($collection as xs:string, $id as xs:string, $directives as map) {
	xmldb:remove($collection, $id || ".xml")
};
```

To hook up RST to your library module you can configure it in the controller.xql of your app or a RESTXQ module. You also have to store some basic settings in your app's config file. Take a look at the sample app in the test directory.

Testing
=======

To see how to setup this library to be actually used in eXist, build the app in the test directory and install it via the package manager. 

JSON-RPC
========

Property | Description
---------|------------
`method` | The (unprefixed) xquery function to execute
`call-id` | An identifier used to match the call in client and server (this is not the same as the resource)
`params` | An array of arguments that the function will take


RESTXQ
======

It would be nice to process RST with RESTXQ. However, currently RESTXQ doesn't allow for regular expressions in path annotations. So unfortunately using this library together with RESTXQ is still pending. See the [rstxq.xql](https://github.com/lagua/xrst/blob/master/test/apps/rst-test/modules/rstxq.xql) file in the test app for annotation examples.


JSON Modeling with JSON Schema and querying with RQL
====================================================
A much more complete standard library will be provided by https://github.com/wshager/xmdl. 
It uses https://github.com/wshager/xrql as its main query processor.
