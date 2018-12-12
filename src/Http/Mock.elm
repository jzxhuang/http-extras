module Http.Mock exposing (expectString, expectJson, expectBytes, expectWhatever, expectStringResponse, expectBytesResponse)

{-| Mock an Http response from within Elm.

Specify exactly what you'd like the response of an Http request to be. The actual resopnse of the Http request is ignored - the response will be exactly what you want to be mocked!

Here's are some examples of how this can be useful!


# Testing your code

Not sure how your code handles an Http request that results in a `Timeout`? Test it by mocking a Timeout response!

    import Http
    import Http.Mock

    type Msg
        = MyMsg (Result Http.Error String)

    testTimeout =
        Http.get
            { url = "https://fakeurl.com"
            , expect = Http.Mock.expectString Http.Timeout_ MyMsg
            }

Note that your `Msg` and `update` logic don't change.
The `expect` functions in Mock have the same return type as the `expect` functions in the default [`Http`][http] library, the only difference is that you specify exactly what the response is!
It doesn't matter what type of request you make - here, we put in a dummy URL, as the response of the request is ignored.


# Mocking an API

Need to quickly mock an API locally? Don't waste time setting up a mock Http server - just mock the response from within Elm!

    import Http
    import Http.Mock

    type Msg
        = MyMsg (Result Http.Error String)

    -- This is our mocked response.
    mockResponse =
        Http.GoodStatus_ <metadata> <body>

    sendRequestLocal =
        Http.get
            { url = "https://fakeurl.com"
            , expect = Http.Mock.expectString mockResponse MyMsg
            }


# Mock

To-do

@docs expectString, expectJson, expectBytes, expectWhatever, expectStringResponse, expectBytesResponse

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response

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



-- Like Http.expectStringResponse, but we try and unbox the response first. i.e. `expect = mockExpectString MyMsg Http.expectJson`


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
