module Http.Mock exposing (expectBytes, expectBytesResponse, expectJson, expectString, expectStringResponse, expectWhatever)

import Bytes exposing (Bytes)
import Bytes.Decode
import Http
import Http.Extras
import Json.Decode


expectString : Http.Response String -> (Result Http.Error String -> msg) -> Http.Expect msg
expectString mockResponse toMsg =
    expectStringResponse mockResponse toMsg Http.Extras.responseToString


expectJson : Http.Response String -> (Result Http.Error a -> msg) -> Json.Decode.Decoder a -> Http.Expect msg
expectJson mockResponse toMsg decoder =
    expectStringResponse mockResponse toMsg <| Http.Extras.responseToJson decoder


expectBytes : Http.Response Bytes -> (Result Http.Error a -> msg) -> Bytes.Decode.Decoder a -> Http.Expect msg
expectBytes mockResponse toMsg decoder =
    expectBytesResponse mockResponse toMsg <| Http.Extras.responseToBytes decoder


expectWhatever : Http.Response Bytes -> (Result Http.Error () -> msg) -> Http.Expect msg
expectWhatever mockResponse toMsg =
    expectBytesResponse mockResponse toMsg Http.Extras.responseToWhatever



-- Like Http.expectStringResponse, but we try and unbox the response first. i.e. `expect = mockExpectString MyMsg Http.expectJson`


expectStringResponse : Http.Response String -> (Result x a -> msg) -> (Http.Response String -> Result x a) -> Http.Expect msg
expectStringResponse mockResponse toMsg toResult =
    Http.expectStringResponse toMsg <|
        \_ -> toResult mockResponse


expectBytesResponse : Http.Response Bytes -> (Result x a -> msg) -> (Http.Response Bytes -> Result x a) -> Http.Expect msg
expectBytesResponse mockResponse toMsg toResult =
    Http.expectBytesResponse toMsg <|
        \_ -> toResult mockResponse
