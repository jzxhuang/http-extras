module Http.Detailed exposing
    ( Error(..), expectString, expectJson, expectBytes, expectWhatever
    , responseToString, responseToJson, responseToBytes, responseToWhatever
    )

{-| Create HTTP requests that return more detailed responses.

The metadata and original body of an HTTP response are often very useful.
Maybe your server returns a useful error message you'd like to try and decode,
or you want to access the header of a successful response.
Unfortunately, this information is discarded in the responses in [`elm/http`][http].
This module lets you create HTTP requests that keep that useful information around.

The API is designed so that usage of this module is exactly the same as using [`elm/http`][http],
with the only difference being that a more detailed `Result` is returned.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0


# Example

Create an HTTP request like you normally would -
just use this module's [`expect`](#expect) functions instead of the ones from the default package.

    import Http
    import Http.Detailed

    type Msg
        = GotText (Result (Http.Detailed.Error String) ( String, Http.Metadata ))
        | ...

    Http.get
        { url = "https://elm-lang.org/assets/public-opinion.txt"
        , expect = Http.Detailed.expectString GotText
        }

If a successful response is received, a `Tuple` containing the expected body and the metadata is returned.
You can access a header from the metadata if needed.

In case of an error, a custom [`Error`](#Error) type is returned which keeps the metadata and body around if applicable,
rather than discarding them. Maybe you want to try and decode the error message!

Your update function might look a bit like this:

    update msg model =
        case msg of
            GotText detailedResponse ->
                case detailedResponse of
                    Ok (text, metadata ) ->
                        -- Do something with the metadata if you need!

                    Err error ->
                        case error of
                            Http.Detailed.BadStatus metadata body statusCode ->
                                -- Try to decode the body - it might be a useful error message!

                            Http.Detailed.Timeout ->
                                -- No metadata is given here - the request timed out

                            ...

            ...


# Expect

Exactly like the `expect` functions from [`elm/http`][http] - usage of the API is the same.
The difference is that the `Result` is more detailed.

  - On a successful response, returns a `Tuple` containing the expected body and the metadata.
  - On an error, returns our custom [`Error`](#Error) type which keeps the metadata and body around if applicable.

A modified version of the examples from [`elm/http`][http] are included for each function to help guide you in using this module.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0

@docs Error, expectString, expectJson, expectBytes, expectWhatever


# Transform

These functions transform an [`Http.Response`][httpResponse] value into the detailed `Result` that is returned in each [`expect`](#Expect) function in this module.
You can use these to build your own `expect` functions.

For example, to create [`Http.Detailed.expectJson`](#expectJson):

    import Http
    import Http.Detailed
    import json.Decode


    expectJson : (Result (Http.Detailed.Error String) ( a, Http.Metadata ) -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
    expectJson toMsg decoder =
        Http.expectStringResponse toMsg (responseToJson decoder)

Use this with [`Mock`](../Http-Mock) to mock a request with a detailed response!

    import Http
    import Http.Detailed
    import Http.Mock


    type Msg
        = GotText (Result (Http.Detailed.Error String) ( String, Http.Metadata ))
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
import Dict
import Http
import Json.Decode



-- type alias Success expected original =
--     { metadata : Http.Metadata
--     , body : expected
--     , originalBody : original
--     }


{-| Our custom error type. Similar to [`Http.Error`][httpError], but keeps the metadata and body around
in `BadStatus` and `BadBody` rather than discarding them. Maybe your API gives a useful error message you want to decode!

The type of the `body` depends on which `expect` function you use.

  - [`expectJson`](#expectJson) and [`expectString`](#expectJson) will return a `String` body
  - [`expectWhatever`](#expectWhatever) and [`expectBytes`](#expectBytes) will return a `Bytes` body.

The `BadBody` state will only be entered when using [`expectJson`](#expectJson) or [`expectBytes`](#expectBytes).

[httpError]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Error

-}
type Error body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata body Int
    | BadBody Http.Metadata body String



-- Expect


{-| A custom type for helping keep track of the state of an HTTP request in your program's Model.

Not sure if this will be included in the final release

-}
type State err success
    = NotRequested
    | Fetching
    | Success ( success, Http.Metadata )
    | Error (Error err)


{-| Expect the response body to be a `String`.

    import Http
    import Http.Detailed

    type Msg
        = GotText (Result (Http.Detailed.Error String) String)

    getPublicOpinion : Cmd Msg
    getPublicOpinion =
        Http.get
            { url = "https://elm-lang.org/assets/public-opinion.txt"
            , expect = Http.Detailed.expectString GotText
            }

On success, return a `Tuple` containing the body as a `String` and the metadata. On error, return our custom [`Error`](#Error) type.

When using this, the error will never be of type `BadBody`.

-}
expectString : (Result (Error String) ( String, Http.Metadata ) -> msg) -> Http.Expect msg
expectString toMsg =
    Http.expectStringResponse toMsg responseToString


{-| Expect the response body to be JSON, and try to decode it.

    import Http
    import Http.Detailed
    import Json.Decode exposing (Decoder, field, string)

    type Msg
        = GotGif (Result (Http.Detailed.Error String) String)

    getRandomCatGif : Cmd Msg
    getRandomCatGif =
        Http.get
            { url = "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=cat"
            , expect = Http.Detailed.expectJson GotGif gifDecoder
            }

    gifDecoder : Decoder String
    gifDecoder =
        field "data" (field "image_url" string)

On success, return a `Tuple` containing the decoded body and the metadata. On error, return our custom [`Error`](#Error) type.

If the JSON decoder fails, you get a `BadBody` error that tries to explain what went wrong.

-}
expectJson : (Result (Error String) ( a, Http.Metadata ) -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg (responseToJson decoder)


{-| Expect the response body to be binary data, and try to decode it.

    import Bytes exposing (Bytes)
    import Bytes.Decode
    import Http
    import Http.Detailed

    type Msg
        = GotData (Result (Http.Detailed.Error Bytes) Data)

    getData : Cmd Msg
    getData =
        Http.get
            { url = "/data"
            , expect = Http.Detailed.expectBytes GotData dataDecoder
            }

    dataDecoder : Bytes.Decode.Decoder Data

    -- This is a Bytes decoder ...

On success, return the a tuple containing the decoded body and the metadata. On error, return our custom [`Error`](#Error) type.

If the Bytes decoder fails, you get a `BadBody` error that just indicates that
_something_ went wrong. You can try to debug by taking a look at the
bytes you are getting in the browser DevTools or something.

-}
expectBytes : (Result (Error Bytes) ( a, Http.Metadata ) -> msg) -> Bytes.Decode.Decoder a -> Http.Expect msg
expectBytes toMsg decoder =
    Http.expectBytesResponse toMsg (responseToBytes decoder)


{-| Expect the response body to be whatever. It does not matter. Ignore it!

    import Http
    import Http.Extras

    type Msg
        = Uploaded (Result (Http.Extras.Error Bytes) ())

    upload : File -> Cmd Msg
    upload file =
        Http.post
            { url = "/upload"
            , body = Http.fileBody file
            , expect = Http.Extras.expectWhatever Uploaded
            }

The server may be giving back a response body, but we do not care about it.

On error, return our custom [`Error`](#Error) type. It will never be `BadBody`.

-}
expectWhatever : (Result (Error Bytes) () -> msg) -> Http.Expect msg
expectWhatever toMsg =
    Http.expectBytesResponse toMsg responseToWhatever



-- Transformers


{-| -}
responseToString : Http.Response String -> Result (Error String) ( String, Http.Metadata )
responseToString responseString =
    resolve
        (\( metadata, body ) -> Ok ( body, metadata ))
        responseString


{-| -}
responseToJson : Json.Decode.Decoder a -> Http.Response String -> Result (Error String) ( a, Http.Metadata )
responseToJson decoder responseString =
    resolve
        (\( metadata, body ) ->
            Result.mapError Json.Decode.errorToString
                (Json.Decode.decodeString (Json.Decode.map (\res -> ( res, metadata )) decoder) body)
        )
        responseString


{-| -}
responseToBytes : Bytes.Decode.Decoder a -> Http.Response Bytes -> Result (Error Bytes) ( a, Http.Metadata )
responseToBytes decoder responseBytes =
    resolve
        (\( metadata, body ) ->
            Result.fromMaybe "Error decoding bytes"
                (Bytes.Decode.decode (Bytes.Decode.map (\res -> ( res, metadata )) decoder) body)
        )
        responseBytes


{-| -}
responseToWhatever : Http.Response Bytes -> Result (Error Bytes) ()
responseToWhatever responseBytes =
    resolve (\_ -> Ok ()) responseBytes



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
            Err (BadStatus metadata body metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            Result.mapError (BadBody metadata body) (toResult ( metadata, body ))
