---
layout: post
title:  ".Net WebHDFS Client (with and without Apache Knox)"
date:   2017-12-19 12:00:00 -0600
tags: bigdata apache hadoop hdfs webhdfs knox .net dotnet csharp C#
---
### TL;DR
.Net [WebHDFS](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/WebHDFS.html) client that works with and without [Apache Knox](https://knox.apache.org).

* Nuget: [https://www.nuget.org/packages/WebHDFS.Client/](https://www.nuget.org/packages/WebHDFS.Client/)
* Source & Example: [https://github.com/risdenk/webhdfs-dotnet](https://github.com/risdenk/webhdfs-dotnet)

### Overview
[WebHDFS](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/WebHDFS.html) is a REST api for [Apache Hadoop HDFS](https://hadoop.apache.org). Existing .Net WebHDFS libraries do not support basic authentication when using [Apache Knox](https://knox.apache.org/). Furthermore, many of the existing implementations against WebHDFS lack features such as streaming files and handling redirects appropriately. Building a library from scratch using .Net HTTP libraries is possible but you need to watch out for a few implementation issues. WebClient is too simple to handle the requirements where as HttpWebRequest requires too much customization to make it work correctly. RestSharp, although it tries to be the best of WebClient and HttpWebRequest, doesn’t handle `PUT` or `POST` uploads well. HttpClient is the best option since it is built into .Net and makes the implementation simple. I put together a new .Net WebHDFS client implementation that accomplishes all of the goals laid out and is published on Nuget as a library. 

### Goals
* Handle redirects
* Stream file (avoid loading into memory)
* Handle basic authentication against Apache Knox

### Existing WebHDFS libraries
I found these existing WebHDFS libraries by searching `webhdfs` in the Nuget gallery. I then reviewed the documentation and source code for each one to explore the features. None of the existing WebHDFS libraries listed below support Knox and many don't support security at all.

* [WebHdfs – justmara](https://www.nuget.org/packages/WebHdfs/)
    * Limited implementation
    * No support for security (basic authentication)
* [WebHdfs.Core – pelhu](https://www.nuget.org/packages/WebHdfs.Core/)
    * Fork for justmara implementation
    * Slightly cleaned up but no new features
* [WebHdfs.Extensions.FileProviders - hcoona](https://www.nuget.org/packages/WebHdfs.Extensions.FileProviders/)
    * Only works with `FileProviders`

### .Net HTTP Libraries
While researching existing WebHDFS libraries, I found that .Net has many different implementations of HTTP libraries. 

* [WebClient](https://msdn.microsoft.com/en-us/library/system.net.webclient.aspx)
    * Built into .Net natively
    * Follows redirect
        * No way to send authentication across the redirect
    * Doesn't have a way to disable following the redirect easily
        * could extend the WebClient class and override the GetRequest method
    * Will upload a file, but copies into memory first
    * Responses are just byte arrays
* [HttpWebRequest](https://msdn.microsoft.com/en-us/library/system.net.httpwebrequest.aspx)
    * Built into .Net natively
    * Very flexible about redirects and authentication
    * Very hard to try to send a file
    * Very low level implementation
* [HttpClient](https://msdn.microsoft.com/en-us/library/system.net.http.httpclient.aspx)
    * Built into .Net natively
        * Requires .Net 4.5
        * Combination of `WebClient` and `HttpWebRequest`
    * Easy to work with
    * Streams file uploads correctly
    * Can serialize/deserialize JSON responses automatically
* [RestSharp](http://restsharp.org/)
    * Not built into .Net natively
    * Terrible implementation of `PUT` and `POST` uploads
        * Assumes all `File` uploads are multipart form uploads
        * Makes it almost impossible to upload binary files
    * Trying to work around file uploads requires copying to byte array

### WebHDFS.Client - A new .Net WebHDFS client
* WebHDFS.Client - [https://www.nuget.org/packages/WebHDFS.Client/](https://www.nuget.org/packages/WebHDFS.Client/)
    * Features
        * Handles basic authentication
        * Handles most of the [WebHDFS API](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/WebHDFS.html)
        * Native classes returned with response objects (except for errors right now)
        * Streams file upload/download
        * Integration tests for a few methods against C# reference server
    * Source and example of use:
        * [https://github.com/risdenk/webhdfs-dotnet/](https://github.com/risdenk/webhdfs-dotnet/)

#### Notes about WebHDFS with Apache Knox
`PreAuthenticate` is misleading when it comes to understanding how 401s are handled. Apache Knox injects a 401 response if there are no `Authorization` headers present in the initial request. The 401s are expected even with the `PreAuthenticate`. `PreAuthenticate` only caches the 401 and then the next request won't have to deal with a 401 if you were to make repeated calls to the same host.

#### WebHDFS with Apache Knox Sequence Diagram - Create File
For reference this is the sequence diagram that is being followed for the WebHDFS create file request through Apache Knox:

<img src="/images/posts/2017-12-19/webhdfs_knox_create_file_sequence_diagram.svg" />

[source](https://sequencediagram.org/index.html?initialData=C4S2BsFMAIHVIEYAkAiAxAytA7gemgNIB2A9gB7QC00AwgE6QCGwMaIUV0GkAjgK6QiAYxgoQjAOZ1GAWwBQcxkOAk6tcCEHA5AB0Z1QQkHqLBoaAKy79h441PQAKtMgAzEAGtrBkEZNnicm9bf2gAGRQAQQAFYN87BwA5WUESABNIOL97MxRme3TMuRoNLUoAPksALnomFmh3KDlLCudGN08ahmYYRsy2jo8KwLIuut72TJHKVpd3DyqAFgAGAEY5AfmZyoslteaLbZLNUz3147KdsZ6GyZx8SL5gAAsD2fb56-q+++hHl42c08w1Io1qNx+eD+T1e03KERiNWekCEHmgjBhcgR0W2Iyq-2eXD4QhEAGdSa4+OA5HDkjJUhkvhMmnSGZBcaCqgBmZYAdhpoO2m06PP5wqGFWqoreFQup2lcuAIPIVW4RDStw4aXyAvIFTywAKjLVGp+2sNcgNRvZytGACZ9tNZaVTg71kA)

