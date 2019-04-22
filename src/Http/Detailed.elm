module Http.Detailed exposing
    ( Error(..), expectString, expectJson, expectBytes, expectWhatever
    , Success, expectStringRecord, expectJsonRecord, expectBytesRecord
    , responseToString, responseToJson, responseToBytes, responseToWhatever
    )

{-| **Create HTTP requests that return more detailed responses.**

_I wrote a [guide explaining how to extract detailed information from HTTP responses in Elm,][Going Beyond 200 OK]
both with and without this package. Giving it a read might help you better understand
the motivation and use cases behind this module!_

---

The metadata and original body of an HTTP response are often very useful.
Maybe your server returns a useful error message you'd like to try and decode,
or you're receiving an auth token in the header of a response.

Unfortunately, this information is discarded in the responses from [`elm/http`][http].
This module lets you create HTTP requests that keep that useful information around.

The API is designed so that usage of this module is exactly the same as using [`elm/http`][http],
with the only difference being that a more detailed `Result` is returned.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[Going Beyond 200 OK]: https://medium.com/@jzxhuang/going-beyond-200-ok-a-guide-to-detailed-http-responses-in-elm-6ddd02322e


# Example

Create an HTTP request like you normally would -
just use this module's [`expect`](#expect) functions instead of the ones from the default package.

    import Http
    import Http.Detailed

    type Msg
        = GotText (Result (Http.Detailed.Error String) ( Http.Metadata, String ))
        | ...

    Http.get
        { url = "https://elm-lang.org/assets/public-opinion.txt"
        , expect = Http.Detailed.expectString GotText
        }

If a successful response is received, a `Tuple` containing the metadata and expected body is returned.
You can access a header from the metadata if needed.

In case of an error, a custom [`Error`](#Error) type is returned which keeps the metadata and body around if applicable,
rather than discarding them. Maybe you want to try and decode the error message!

Your update function might look a bit like this:

    update msg model =
        case msg of
            GotText detailedResponse ->
                case detailedResponse of
                    Ok ( metadata, text ) ->
                        -- Do something with the metadata if you need!

                    Err error ->
                        case error of
                            Http.Detailed.BadStatus metadata body ->
                                -- Try to decode the body - it might be a useful error message!

                            Http.Detailed.Timeout ->
                                -- No metadata is given here - the request timed out

                            ...

            ...


# Expect (Tuple)

Exactly like the `expect` functions from [`elm/http`][http] - usage of the API is the same.
The difference is that the `Result` is more detailed.

  - On a successful response, returns a `Tuple` containing the expected body and the metadata.
  - On an error, returns our custom [`Error`](#Error) type which keeps the metadata and body around if applicable.

A modified version of the examples from [`elm/http`][http] are included for each function to help guide you in using this module.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0

@docs Error, expectString, expectJson, expectBytes, expectWhatever


# Expect (Record)

Prefer a record rather than a Tuple? Use these functions instead. Same as the `expect` functions above,
but on a successful response returns a record of our custom type [`Success`](#Success) instead of a Tuple.

@docs Success, expectStringRecord, expectJsonRecord, expectBytesRecord


# Transform

These functions transform an [`Http.Response`][httpResponse] value into the detailed `Result` that is returned in each [`expect`](#Expect) function in this module.
You can use these to build your own `expect` functions.

For example, to create [`Http.Detailed.expectJson`](#expectJson):

    import Http
    import Http.Detailed
    import json.Decode


    expectJson : (Result (Http.Detailed.Error String) ( Http.Metadata, a ) -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
    expectJson toMsg decoder =
        Http.expectStringResponse toMsg (responseToJson decoder)

Use this with [`Mock`](../Http-Mock) to mock a request with a detailed response!

    import Http
    import Http.Detailed
    import Http.Mock


    type Msg
        = GotText (Result (Http.Detailed.Error String) ( Http.Metadata, String ))
        | ...


    -- Mock a request, with a Detailed Result!

    Http.get
        { url = "https://fakeurl.com"
        , expect = Http.Mock.expectStringResponse Http.Timeout_ GotText Http.Detailed.responseToString
        }

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

@docs responseToString, responseToJson, responseToBytes, responseToWhatever

-}

import Bytes exposing (Bytes)
import Bytes.Decode
import Http
import Json.Decode


{-| Our custom error type. Similar to [`Http.Error`][httpError], but keeps the metadata and body around
in `BadStatus` and `BadBody` rather than discarding them. Maybe your API gives a useful error message you want to decode!

`body` can be either `String` or `Bytes`, depending on which `expect` function you use.

  - [`expectJson`](#expectJson) and [`expectString`](#expectJson) will return a `String` body
  - [`expectWhatever`](#expectWhatever) and [`expectBytes`](#expectBytes) will return a `Bytes` body.

The `BadBody` state will only be entered when using [`expectJson`](#expectJson) or [`expectBytes`](#expectBytes).

[httpError]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Error

-}
type Error body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata body
    | BadBody Http.Metadata body String



-- Expect (Tuple)


{-| Expect the response body to be a `String`.

    import Http
    import Http.Detailed

    type Msg
        = GotText (Result (Http.Detailed.Error String) ( Http.Metadata, String ))

    getPublicOpinion : Cmd Msg
    getPublicOpinion =
        Http.get
            { url = "https://elm-lang.org/assets/public-opinion.txt"
            , expect = Http.Detailed.expectString GotText
            }

On success, return a `Tuple` containing the metadata and the body as a `String`. On error, return our custom [`Error`](#Error) type.

When using this, the error will never be of type `BadBody`.

-}
expectString : (Result (Error String) ( Http.Metadata, String ) -> msg) -> Http.Expect msg
expectString toMsg =
    Http.expectStringResponse toMsg responseToString


{-| Expect the response body to be JSON, and try to decode it.

    import Http
    import Http.Detailed
    import Json.Decode exposing (Decoder, field, string)

    type Msg
        = GotGif (Result (Http.Detailed.Error String) ( Http.Metadata, String ))

    getRandomCatGif : Cmd Msg
    getRandomCatGif =
        Http.get
            { url = "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=cat"
            , expect = Http.Detailed.expectJson GotGif gifDecoder
            }

    gifDecoder : Decoder String
    gifDecoder =
        field "data" (field "image_url" string)

On success, return a `Tuple` containing the metadata and the decoded body. On error, return our custom [`Error`](#Error) type.

If the JSON decoder fails, you get a `BadBody` error that tries to explain what went wrong.

-}
expectJson : (Result (Error String) ( Http.Metadata, a ) -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg (responseToJson decoder)


{-| Expect the response body to be binary data, and try to decode it.

    import Bytes exposing (Bytes)
    import Bytes.Decode
    import Http
    import Http.Detailed

    type Msg
        = GotData (Result (Http.Detailed.Error Bytes) ( Http.Metadata, Data ))

    getData : Cmd Msg
    getData =
        Http.get
            { url = "/data"
            , expect = Http.Detailed.expectBytes GotData dataDecoder
            }

    dataDecoder : Bytes.Decode.Decoder Data

    -- This is a Bytes decoder (not implemented)...

On success, return the a tuple containing the metadata and the decoded body. On error, return our custom [`Error`](#Error) type.

If the Bytes decoder fails, you get a `BadBody` error that just indicates that
_something_ went wrong. You can try to debug by taking a look at the
bytes you are getting in the browser DevTools or something.

-}
expectBytes : (Result (Error Bytes) ( Http.Metadata, a ) -> msg) -> Bytes.Decode.Decoder a -> Http.Expect msg
expectBytes toMsg decoder =
    Http.expectBytesResponse toMsg (responseToBytes decoder)


{-| Expect the response body to be whatever. It does not matter. Ignore it!

    import Http
    import Http.Detailed

    type Msg
        = Uploaded (Result (Http.Detailed.Error Bytes) ())

    upload : File -> Cmd Msg
    upload file =
        Http.post
            { url = "/upload"
            , body = Http.fileBody file
            , expect = Http.Detailed.expectWhatever Uploaded
            }

The server may be giving back a response body, but we do not care about it.

On error, return our custom [`Error`](#Error) type. It will never be `BadBody`.

-}
expectWhatever : (Result (Error Bytes) () -> msg) -> Http.Expect msg
expectWhatever toMsg =
    Http.expectBytesResponse toMsg responseToWhatever



-- Expect (Record)


{-| A custom type containing the full details for a successful response as a record.

body can be either String or Bytes, depending on which expect function you use.

-}
type alias Success body =
    { metadata : Http.Metadata
    , body : body
    }


{-| -}
expectStringRecord : (Result (Error String) (Success String) -> msg) -> Http.Expect msg
expectStringRecord toMsg =
    Http.expectStringResponse toMsg responseToStringRecord


{-| -}
expectJsonRecord : (Result (Error String) (Success a) -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
expectJsonRecord toMsg decoder =
    Http.expectStringResponse toMsg (responseToJsonRecord decoder)


{-| -}
expectBytesRecord : (Result (Error Bytes) (Success a) -> msg) -> Bytes.Decode.Decoder a -> Http.Expect msg
expectBytesRecord toMsg decoder =
    Http.expectBytesResponse toMsg (responseToBytesRecord decoder)



-- Transformers


{-| -}
responseToString : Http.Response String -> Result (Error String) ( Http.Metadata, String )
responseToString responseString =
    resolve
        (\( metadata, body ) -> Ok ( metadata, body ))
        responseString


{-| -}
responseToJson : Json.Decode.Decoder a -> Http.Response String -> Result (Error String) ( Http.Metadata, a )
responseToJson decoder responseString =
    resolve
        (\( metadata, body ) ->
            Result.mapError Json.Decode.errorToString
                (Json.Decode.decodeString (Json.Decode.map (\res -> ( metadata, res )) decoder) body)
        )
        responseString


{-| -}
responseToBytes : Bytes.Decode.Decoder a -> Http.Response Bytes -> Result (Error Bytes) ( Http.Metadata, a )
responseToBytes decoder responseBytes =
    resolve
        (\( metadata, body ) ->
            Result.fromMaybe "Error decoding bytes"
                (Bytes.Decode.decode (Bytes.Decode.map (\res -> ( metadata, res )) decoder) body)
        )
        responseBytes


{-| -}
responseToWhatever : Http.Response Bytes -> Result (Error Bytes) ()
responseToWhatever responseBytes =
    resolve (\_ -> Ok ()) responseBytes


{-| -}
responseToStringRecord : Http.Response String -> Result (Error String) (Success String)
responseToStringRecord responseString =
    resolve
        (\( metadata, body ) -> Ok (Success metadata body))
        responseString


{-| -}
responseToJsonRecord : Json.Decode.Decoder a -> Http.Response String -> Result (Error String) (Success a)
responseToJsonRecord decoder responseString =
    resolve
        (\( metadata, body ) ->
            Result.mapError Json.Decode.errorToString
                (Json.Decode.decodeString (Json.Decode.map (\res -> Success metadata res) decoder) body)
        )
        responseString


{-| -}
responseToBytesRecord : Bytes.Decode.Decoder a -> Http.Response Bytes -> Result (Error Bytes) (Success a)
responseToBytesRecord decoder responseBytes =
    resolve
        (\( metadata, body ) ->
            Result.fromMaybe "Error decoding bytes"
                (Bytes.Decode.decode (Bytes.Decode.map (\res -> Success metadata res) decoder) body)
        )
        responseBytes



-- Helper for the transformers


resolve : (( Http.Metadata, body ) -> Result String a) -> Http.Response body -> Result (Error body) a
resolve toResult response =
    case response of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (BadStatus metadata body)

        Http.GoodStatus_ metadata body ->
            Result.mapError (BadBody metadata body) (toResult ( metadata, body ))
