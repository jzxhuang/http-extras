module Http.Extras exposing
    ( Request, generateQueryString, generateHeaders, State(..)
    , expectRawString, expectRawBytes
    , responseToString, responseToJson, responseToBytes, responseToWhatever
    , getBody, getHeaders, getMetadata, getStatusCode, getStatusText, getUrl, isSuccess
    )

{-| Convenience functions for working with the default Http library.


# Requests

Helpers for creating Http requests.

@docs Request, generateQueryString, generateHeaders, State


# Responses

Helpers for working with an [`Http.Response`][httpResponse] value.


## Expect

[`expectRawString`](#expectRawString) and [`expectRawBytes`](#expectRawBytes) are convenience functions for helping you build your own custom, advanced handlers for interpreting an Http response.
These functions return an [`Http.Response`][httpResponse] wrapped in a Result, where the `Result` will _**always**_ be `Ok`. Handle the [`Http.Response`][httpResponse] however you'd like!

@docs expectRawString, expectRawBytes


## Transform

Transform an [`Http.Response`][httpResponse] value into the respective `Result` that is returned in each `_expect_` function from [`Http`][http].

@docs responseToString, responseToJson, responseToBytes, responseToWhatever


## Getters

Getters for extracting information like the header, status code, url, etc. from a [`Http.Response`][httpResponse] value.

@docs getBody, getHeaders, getMetadata, getStatusCode, getStatusText, getUrl, isSuccess

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

-}

import Bytes exposing (Bytes)
import Bytes.Decode
import Dict
import Http
import Json.Decode


{-| The type that needs to be passed into `[Http.request](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#request)` It's never actually defined as a type in the default package, so this is just the type definition for it.
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


{-| A custom type for helping keep track of the state of an Http request in your program's Model.
-}
type State success
    = NotRequested
    | Fetching
    | Success ( success, Http.Metadata )
    | Error Http.Error


{-| Generate a query string to append to your URL.

    generateQueryString [ ( "foo", "abc" ), ( "bar", "xyz" ) ]
        == "?foo=abc&bar=xyz"

-}
generateQueryString : List ( String, String ) -> String
generateQueryString queries =
    "?" ++ (List.map (\( field, value ) -> field ++ "=" ++ value) queries |> String.join "&")


{-| Generate a list of Http headers.

generateheaders [ ( "Max-Forwards", "10"), ( "Authorization", "Basic abc123" ) ]

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


{-| -}
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


{-| -}
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
-- (Response body -> Result (Http.Error body) a)


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



-- This is basically like expectString! But for Bytes


{-| -}
responseToWhatever : Http.Response Bytes -> Result Http.Error ()
responseToWhatever responseBytes =
    resolve (\_ -> Ok ()) responseBytes



-- Helper function for the transfomers


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
