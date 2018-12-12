module Http.Detailed exposing
    ( Error(..), State(..), expectString, expectJson, expectBytes, expectWhatever
    , responseToJson, responseToString, responseToWhatever, responseToBytes
    )

{-| More detailed Http responses.

The metadata and original body of an Http response are useful - maybe you want to try and decode the error message your server returned, or you need to access a header even after decoding the body as a Json.

This module defines a custom Error and Success type that includes the original metadata and body of the response.


# Example

Creating an Http request looks almost exactly the same - all you have to do is use this package's `expect` functions.

    import Http
    import Http.Detailed
    import Json.Decode as D


    type Msg
    = MyMsg (Result (Http.Detailed.Error String) ( String,  Http.Metadata, String ))


    -- Send some requests
    Http.get { url = "myurl", expect = Http.Detailed.expectString MyMsg }

The package defines custom `Error` and `Sucess` types which contain the metadata and original body when applicable. So, your update function might look a bit like this:

    update msg model =
        case msg of
            MyMsg response ->
                case response of
                    Ok (response, metadata ) ->
                        -- Do something with the metadata!

                    Err error ->
                        case error of
                            Http.Detailed.BadStatus metadata body statusCode ->
                                -- Try to decode the body - it might be a useful error message!


# Expect

Exactly like the `expect` functions from [`Http][http], but using [`Http.Extras.Error](#Error) to keep the metadata and body around rather than discarding it.

@docs Error, State, expectString, expectJson, expectBytes, expectWhatever


# Transform

@docs responseToJson, responseToString, responseToWhatever, responseToBytes
@docs [http]: https://package.elm-lang.org/packages/elm/http/2.0.0
@docs [httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

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


{-| Similar to Http.Error, but keeps the metadata and body in `BadStatus` and `BadBody` rather than discarding it. Maybe your API gives useful error messages!

The type of the `body` depends on which _expect_ function you use. [`expectJson`](#expectJson), [`expectString`](#expectJson) and [`expectRawString`](#expectRawString)
will return a `String` body, while [`expectWhatever`](#expectWhatever), [`expectBytes`](#expectBytes) and [`expectRawBytes`](#expectRawBytes) will return a `Bytes` type.

The `BadBody` will only be entered when using [`expectJson`](#expectJson) or [`expectBytes`](#expectBytes)
|

-}
type Error body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata body Int
    | BadBody Http.Metadata body String


type State body success
    = NotRequested
    | Fetching
    | Success success
    | Error (Error body)


{-| Expect the response body to be a `String`. Just like [`Http.expectString`][httpString], but with our new Error type that doesn't discard the metadata and body.

When using this, the `Error` will never be of type `BadBody`.

Here's a modified version of the example from [`Http`][httpString]

    import Http
    import Http.Extras

    type Msg
        = GotText (Result (Http.Extras.Error String) String)

    getPublicOpinion : Cmd Msg
    getPublicOpinion =
        Http.get
            { url = "https://elm-lang.org/assets/public-opinion.txt"
            , expect = Http.Extras.expectString GotText
            }

[httpString]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#expectString

-}
expectString : (Result (Error String) ( String, Http.Metadata ) -> msg) -> Http.Expect msg
expectString toMsg =
    Http.expectStringResponse toMsg responseToString


{-| Expect the response body to be JSON, and try to decode it. Just like [`Http.expectJson`][httpJson], but with our new Error type that doesn't discard the metadata and body.

If the JSON decoder fails, you get a `BadBody` error that tries to explain what went wrong.

Here's a modified version of the example from `Http`][httpJson]

    import Http
    import Http.Extras
    import Json.Decode exposing (Decoder, field, string)

    type Msg
        = GotGif (Result (Http.Extras.Error String) String)

    getRandomCatGif : Cmd Msg
    getRandomCatGif =
        Http.get
            { url = "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=cat"
            , expect = Http.Extras.expectJson GotGif gifDecoder
            }

    gifDecoder : Decoder String
    gifDecoder =
        field "data" (field "image_url" string)

[httpJson]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#expectJson

-}
expectJson : (Result (Error String) ( a, Http.Metadata ) -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg (responseToJson decoder)


{-| Expect the response body to be binary data, and try to decode it. Just like [`Http.expectBytes`][httpBytes], but with our new Error type that doesn't discard the metadata and body.

If the Bytes decoder fails, you get a `BadBody` error that just indicates that
_something_ went wrong. It probably makes sense to debug by peeking at the
bytes you are getting in the browser developer tools or something.

Here's a modified version of the example from `Http`][httpBytes]

    import Bytes exposing (Bytes)
    import Bytes.Decode
    import Http
    import Http.Extras

    type Msg
        = GotData (Result (Http.Extras.Error Bytes) Data)

    getData : Cmd Msg
    getData =
        Http.get
            { url = "/data"
            , expect = Http.Extras.expectBytes GotData dataDecoder
            }


    -- dataDecoder : Bytes.Decoder Data

You would use [`elm/bytes`](/packages/elm/bytes/latest/) to decode the binary
data according to a proto definition file like `example.proto`.

[httpBytes]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#expectBytes

-}
expectBytes : (Result (Error Bytes) ( a, Http.Metadata ) -> msg) -> Bytes.Decode.Decoder a -> Http.Expect msg
expectBytes toMsg decoder =
    Http.expectBytesResponse toMsg (responseToBytes decoder)


{-| Expect the response body to be whatever. It does not matter. Ignore it! Just like [`Http.expectBytes`][httpWhatever], but with our new Error type that doesn't discard the metadata and body.

Here's a modified version of the example from `Http`][httpWhatever]

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

[httpWhatever]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#expectWhatever

-}
expectWhatever : (Result (Error Bytes) () -> msg) -> Http.Expect msg
expectWhatever toMsg =
    Http.expectBytesResponse toMsg responseToWhatever



-- (Response body -> Result (Error body) a)


responseToString : Http.Response String -> Result (Error String) ( String, Http.Metadata )
responseToString responseString =
    resolve
        (\( metadata, body ) -> Ok ( body, metadata ))
        responseString


responseToJson : Json.Decode.Decoder a -> Http.Response String -> Result (Error String) ( a, Http.Metadata )
responseToJson decoder responseString =
    resolve
        (\( metadata, body ) ->
            Result.mapError Json.Decode.errorToString
                (Json.Decode.decodeString (Json.Decode.map (\res -> ( res, metadata )) decoder) body)
        )
        responseString


responseToBytes : Bytes.Decode.Decoder a -> Http.Response Bytes -> Result (Error Bytes) ( a, Http.Metadata )
responseToBytes decoder responseBytes =
    resolve
        (\( metadata, body ) ->
            Result.fromMaybe "Error decoding bytes"
                (Bytes.Decode.decode (Bytes.Decode.map (\res -> ( res, metadata )) decoder) body)
        )
        responseBytes



-- This is basically like expectString! But for Bytes


responseToWhatever : Http.Response Bytes -> Result (Error Bytes) ()
responseToWhatever responseBytes =
    resolve (\_ -> Ok ()) responseBytes


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
