module Http.Detailed exposing
    ( Error(..), State(..), expectString, expectJson, expectBytes, expectWhatever
    , responseToJson, responseToString, responseToWhatever, responseToBytes
    )

{-| More detailed Http responses.

The metadata and original body of an Http response are often useful - maybe you want to try and decode the error message your server returned, or you need to access a header even after decoding the body as a Json.
Unfortunately, this information is not returned in the default `Http` library.

This module helps you create Http requests with more detailed responses by returning a`Result` type that contains more information in it.


# Example

Creating an Http request looks almost exactly the same - simply use this module's `_expect_` functions.

    import Http
    import Http.Detailed


    type Msg
    = MyMsg (Result (Http.Detailed.Error String) ( String, Http.Metadata ))


    -- Send some requests
    Http.get { url = "myurl", expect = Http.Detailed.expectString MyMsg }

Notice the `Result` will be either a custom `Error` or a Tuple containing the expected response as well as the metadata.

Your update function might look a bit like this:

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

Exactly like the `expect` functions from [`Http`][http], but with more details in the `Result` that is returned!

On an error, returns our custom [`Error`](#Error) type which keeps the metadata and body around rather than discarding them.
You might want to try and decode the error message!

On a successful response, return the expected body as well as the metadata. You might need to access a header from the metadata!

@docs Error, State, expectString, expectJson, expectBytes, expectWhatever


# Transform

Transform an [`Http.Response`][httpResponse] value into the respective `Result` that is returned in each `_expect_` function from [`Http`][http].

@docs responseToJson, responseToString, responseToWhatever, responseToBytes

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

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


{-| Similar to Http.Error, but keeps the metadata and body in `BadStatus` and `BadBody` rather than discarding it. Maybe your API gives a useful error message you want to decode!

The type of the `body` depends on which _expect_ function you use. [`expectJson`](#expectJson) and [`expectString`](#expectJson)
will return a `String` body, while [`expectWhatever`](#expectWhatever) and [`expectBytes`](#expectBytes) will return a `Bytes` type.

The `BadBody` state will only be entered when using [`expectJson`](#expectJson) or [`expectBytes`](#expectBytes).
|

-}
type Error body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata body Int
    | BadBody Http.Metadata body String


{-| A custom type for helping keep track of the state of an Http request in your program's Model.
-}
type State err success
    = NotRequested
    | Fetching
    | Success ( success, Http.Metadata )
    | Error (Error err)


{-| Expect the response body to be a `String`.

Just like [`Http.expectString`][httpString], but with more details. On success, return the body and the metadata. On error, return our custom error type.

When using this, the `Error` will never be of type `BadBody`.

Here's a modified version of the example from the original [`Http package`][httpString]

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


{-| Expect the response body to be JSON, and try to decode it.

Just like [`Http.expectJson`][httpJson], but with more details. On success, return the decoded body and the metadata. On error, return our custom error type.

If the JSON decoder fails, you get a `BadBody` error that tries to explain what went wrong.

Here's a modified version of the example from the original [`Http package`][httpJson]

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


{-| Expect the response body to be binary data, and try to decode it.

Just like [`Http.expectBytes`][httpBytes], but with more details. On success, return the decoded body and the metadata. On error, return our custom error type.

If the Bytes decoder fails, you get a `BadBody` error that just indicates that
_something_ went wrong. It probably makes sense to debug by peeking at the
bytes you are getting in the browser developer tools or something.

Here's a modified version of the example from the original [`Http package`][httpBytes]

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


{-| Expect the response body to be whatever. It does not matter. Ignore it!

Just like [`Http.expectBytes`][httpWhatever], but with more details. On error, return our custom error type.

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



-- Helper for the trasnformers


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
