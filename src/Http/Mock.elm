module Http.Mock exposing (expectString, expectJson, expectBytes, expectWhatever, expectStringResponse, expectBytesResponse)

{-| Mock an HTTP response from within Elm.

Specify exactly what you'd like the response of an HTTP request to be.
The actual response of the HTTP request is ignored - the response will be exactly what you want to be mocked!

Here's are some examples of how this can be useful.


# Testing your code

Not sure how your code handles an HTTP request that results in a `Timeout`? Test it by mocking a Timeout response!

    import Http
    import Http.Mock

    type Msg
        = MyResponseHandler (Result Http.Error String)

    testTimeout =
        Http.get
            { url = "https://fakeurl.com"
            , expect = Http.Mock.expectString Http.Timeout_ MyResponseHandler
            }

Your update logic doesn't change - mock a `Timeout` response and make sure your program handles it correctly!
Notice that we put in a dummy URL here - It doesn't matter what type of request you make, as the response of the request will be exactly what you specify.


# Mocking an API

Need to quickly mock an API locally? Don't waste time setting up a fake HTTP server for testing - just mock the response directly from within Elm!

    import Http
    import Http.Mock

    type Msg
        = MyResponseHandler (Result Http.Error String)

    -- This is our mocked response.
    -- You would actually put metadata and a body!
    mockResponse =
        Http.GoodStatus_ <metadata> <body>

    sendRequestWithMockedResponse =
        Http.get
            { url = "https://fakeurl.com"
            , expect = Http.Mock.expectString mockResponse MyResponseHandler
            }

Again, your update logic should not change, and it doesn't matter what type of request you make - the response is discarded in favor of the mocked response.

When using this module, it would be a good idea to store all your mocked responses in a separate file.


# Mock

The API is designed so that usage of this module is almost identical to using the default [Http][http] package.
Simply specify exactly what you want the response to be - everything else looks the same.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0

@docs expectString, expectJson, expectBytes, expectWhatever, expectStringResponse, expectBytesResponse

-}

import Bytes exposing (Bytes)
import Bytes.Decode
import Http
import Http.Extras
import Json.Decode


{-| -}
expectString : Http.Response String -> (Result Http.Error String -> msg) -> Http.Expect msg
expectString mockResponse toMsg =
    expectStringResponse mockResponse toMsg Http.Extras.responseToString


{-| -}
expectJson : Http.Response String -> (Result Http.Error a -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
expectJson mockResponse toMsg decoder =
    expectStringResponse mockResponse toMsg <| Http.Extras.responseToJson decoder


{-| -}
expectBytes : Http.Response Bytes -> (Result Http.Error a -> msg) -> Bytes.Decode.Decoder a -> Http.Expect msg
expectBytes mockResponse toMsg decoder =
    expectBytesResponse mockResponse toMsg <| Http.Extras.responseToBytes decoder


{-| -}
expectWhatever : Http.Response Bytes -> (Result Http.Error () -> msg) -> Http.Expect msg
expectWhatever mockResponse toMsg =
    expectBytesResponse mockResponse toMsg Http.Extras.responseToWhatever


{-| -}
expectStringResponse : Http.Response String -> (Result x a -> msg) -> (Http.Response String -> Result x a) -> Http.Expect msg
expectStringResponse mockResponse toMsg toResult =
    Http.expectStringResponse toMsg <|
        \_ -> toResult mockResponse


{-| -}
expectBytesResponse : Http.Response Bytes -> (Result x a -> msg) -> (Http.Response Bytes -> Result x a) -> Http.Expect msg
expectBytesResponse mockResponse toMsg toResult =
    Http.expectBytesResponse toMsg <|
        \_ -> toResult mockResponse
