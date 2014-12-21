RST
===

CRUD and JSON-RPC mask for REST written in Xquery

To install in eXist-db:
--------------------

Download and install eXist-db 2.2 at http://exist-db.org

Build the package and install into eXist using the manager in the dashboard.

--------

Why a CRUD mask for REST?

RST provides a standard way to handle CRUD and JSON-RPC functionality, so you don't need to concern yourself with HTTP methods, content negotiation and architectural decisions. The standard that this library embraces has been developed within the javascript community.

While working on projects with [Dojo Toolkit](http://dojotoolkit.org), it became clear to me that the Dojo concept 
of what REST is and should be is quite concise. The client library has been developed in tandem with 
[Persevere](http://persvr.org), a Dojo Foundation project for the server. It follows these principles:

* A target path (from a REST perspective) is considered to be /path/to/collection
* The entire path following the collection is considered to be an id, and may contain slashes. 
This departs from some other concepts, where path fragments are used to denote subsets of the data-model, 
specific functionality on the data-set or even unrelated data.
* The functions that are used for CRUD on the client-side are mirrored on the server-side. These are: 
get, query, put, and delete.
* In addition, contents may be posted that triggers custom functionality (JSON-RPC), either on a specific resource 
or the entire collection.

Please note that this library DOES NOT actually perform any of these actions! It merely provides 
an intermediary step between RESTXQ and another library that takes care of the actual database manipulation.

The core functions perform the following actions (largely taken from https://github.com/persvr/perstore):

* `get` retrieves a resource by its id.
* `query` retrieves the entire collection of resources, that may then be filtered, sorted and paged.
* `put` creates or updates a resource. The resource may or may not already exist. 
An optional parameter defines the primary identifier for storing the resource. 
If that is not specified, the id may be auto-generated. The created/updated resource should be returned.
* `delete` deletes the resources with the given identifier from the collection.

An example library module that will be consumed by rst could be this:

```xquery
xquery version "3.0";

declare module namespace service="http://my/services/simple";

declare function service:get($collection as xs:anyURI,$id as xs:string, $directives as map) {
	doc($collection || "/" || $id || ".xml")
};

declare function service:query($collection as xs:anyURI, $query as xs:anyType, $directives as map) {
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

declare function service:delete($collection as xs:anyURI, $id as xs:string, $directives as map) {
	xmldb:remove($collection, $id || ".xml")
};
```

Testing
=======

To see how to setup this library to be actually used in eXist, build the app in the test directory and install it via the package manager.  

RESTXQ
======

It would be nice to process RST with RESTXQ. However, currently RESTXQ doesn't allow for regular expressions in path annotations. So unfortunately using this library together with RESTXQ is still pending. See the [rstxq.xql](https://github.com/lagua/xrst/blob/master/test/apps/rst-test/modules/rstxq.xql) file in the test app for annotation examples.


JSON Modeling with JSON Schema and querying with RQL
====================================================
A much more complete standard library will be provided by the next version of https://github.com/lagua/xmdl. 
It will use https://github.com/lagua/xrql as its main query processor.
