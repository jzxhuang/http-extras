module Http.Extras exposing
    ( Request, generateQuery, generateHeaders
    , expectRawString, expectRawBytes
    , responseToString, responseToJson, responseToBytes, responseToWhatever
    , getUrl, getStatusCode, getStatusText, getHeaders, getMetadata, getBody, isSuccess
    )

{-| Convenience functions for creating HTTP requests and interpreting an HTTP response.


# Requests

Helpers for creating HTTP requests.

@docs Request, generateQuery, generateHeaders


# Responses

Helpers for interpreting an [`Http.Response`][httpResponse] value.

[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response


## Expect

[`expectRawString`](#expectRawString) and [`expectRawBytes`](#expectRawBytes) are convenience functions for helping you build your own custom, advanced handlers for interpreting an Http response.
These functions return an [`Http.Response`][httpResponse] wrapped in a Result, where the `Result` will _**always**_ be `Ok`. Handle the [`Http.Response`][httpResponse] however you'd like!

**Note:** These functions will likely be removed - they don't seem too useful.

@docs expectRawString, expectRawBytes


## Transform

Transform an [`Http.Response`][httpResponse] value into the respective `Result` that is returned in each `expect` function from [`Http`][http].

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

@docs responseToString, responseToJson, responseToBytes, responseToWhatever


## Getters

Convenience functions for extracting information like the header, status code, url, etc. from a [`Http.Response`][httpResponse] value.
On an error, a short string will be returned describing why the error occurred. For example:

    getStatusCode Http.Timeout_
        == Err "Timeout"

These functions are primarily concerned with accessing the metadata of a response.
So, these functions will return a successful `Result` if the response is `GoodStatus_` or `BadStatus_`.
Otherwise, the `Result` will be an error.

[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

@docs getUrl, getStatusCode, getStatusText, getHeaders, getMetadata, getBody, isSuccess

-}

import Bytes exposing (Bytes)
import Bytes.Decode
import Dict
import Http
import Json.Decode
import Url.Builder


{-| The type that needs to be passed into [`Http.request`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#request).
It's never actually defined as a type in the default package, so this is just the type definition for it.
-}
type alias Request msg =
    { method : String
    , headers : List Http.Header
    , url : String
    , body : Http.Body
    , expect : Http.Expect msg
    , timeout : Maybe Float
    , tracker : Maybe String
    }


{-| A custom type for helping keep track of the state of an HTTP request in your program's Model.

Not sure if this will be included in the final version.

-}
type State success
    = NotRequested
    | Fetching
    | Success success
    | Error Http.Error


{-| Convenience function to generate a [percent-encoded](https://tools.ietf.org/html/rfc3986#section-2.1) query string from a list of `( String, String )`.

    generateQuery [ ( "foo", "abc 123" ), ( "bar", "xyz" ) ]
        == "?foo=abc%20123&bar=xyz"

**Note:** It seems that this function should not be a part of this library, and it would be more appropriate in something
like Url.Extras. I only have this function here for now because it is something I use frequently...

-}
generateQuery : List ( String, String ) -> String
generateQuery queries =
    List.map (\( field, value ) -> Url.Builder.string field value) queries
        |> Url.Builder.toQuery


{-| Convenience function to generate a list of [`Http.Header`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Header)
from a list of `( String, String )`.

    generateHeaders [ ( "Max-Forwards", "10" ), ( "Authorization", "Basic pw123" ) ]
        == [ Http.Header "Max-Forwards" "10", Http.Header "Authorization" "Basic pw123" ]

-}
generateHeaders : List ( String, String ) -> List Http.Header
generateHeaders headers =
    List.map (\( field, value ) -> Http.header field value) headers


{-| -}
expectRawString : (Result Http.Error (Http.Response String) -> msg) -> Http.Expect msg
expectRawString toMsg =
    Http.expectStringResponse toMsg <|
        \httpResponse ->
            Ok httpResponse


{-| -}
expectRawBytes : (Result Http.Error (Http.Response Bytes) -> msg) -> Http.Expect msg
expectRawBytes toMsg =
    Http.expectBytesResponse toMsg <|
        \httpResponse ->
            Ok httpResponse



-- Convenience Functions for Http.Response


{-| Note that this only tries to return the url from the metadata - it does not return the url if
the response is `BadUrl_`
-}
getUrl : Http.Response body -> Result String String
getUrl res =
    Result.map .url (getMetadata res)


{-| -}
getStatusCode : Http.Response body -> Result String Int
getStatusCode res =
    Result.map .statusCode (getMetadata res)


{-| -}
getStatusText : Http.Response body -> Result String String
getStatusText res =
    Result.map .statusText (getMetadata res)


{-| -}
getHeaders : Http.Response body -> Result String (Dict.Dict String String)
getHeaders res =
    Result.map .headers (getMetadata res)


{-| Returns the status code if 200 <= status code < 300
-}
isSuccess : Http.Response body -> Result String Int
isSuccess res =
    case getStatusCode res of
        Err err ->
            Err err

        Ok code ->
            if 200 <= code && code < 300 then
                Ok code

            else
                Err <| "Bad status: " ++ String.fromInt code


{-| -}
getMetadata : Http.Response body -> Result String Http.Metadata
getMetadata res =
    Result.map
        (\( metadata, _ ) -> metadata)
        (parseResponse res)


{-| -}
getBody : Http.Response body -> Result String body
getBody res =
    Result.map
        (\( _, body ) -> body)
        (parseResponse res)



-- Helper for getMetadata and getBody


parseResponse : Http.Response body -> Result String ( Http.Metadata, body )
parseResponse res =
    case res of
        Http.BadUrl_ url ->
            Err "Bad Url"

        Http.Timeout_ ->
            Err "Timeout"

        Http.NetworkError_ ->
            Err "Network Error"

        Http.BadStatus_ metadata body ->
            Ok ( metadata, body )

        Http.GoodStatus_ metadata body ->
            Ok ( metadata, body )



-- Transformers


{-| -}
responseToString : Http.Response String -> Result Http.Error String
responseToString responseString =
    resolve Ok responseString


{-| -}
responseToJson : Json.Decode.Decoder a -> Http.Response String -> Result Http.Error a
responseToJson decoder responseString =
    resolve
        (\res -> Result.mapError Json.Decode.errorToString (Json.Decode.decodeString decoder res))
        responseString


{-| -}
responseToBytes : Bytes.Decode.Decoder a -> Http.Response Bytes -> Result Http.Error a
responseToBytes decoder responseBytes =
    resolve
        (\res -> Result.fromMaybe "Error decoding bytes" (Bytes.Decode.decode decoder res))
        responseBytes


{-| -}
responseToWhatever : Http.Response Bytes -> Result Http.Error ()
responseToWhatever responseBytes =
    resolve (\_ -> Ok ()) responseBytes



-- Helper function for the Transfomers


resolve : (body -> Result String a) -> Http.Response body -> Result Http.Error a
resolve toResult response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata _ ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ _ body ->
            Result.mapError Http.BadBody (toResult body)
