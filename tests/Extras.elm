module Extras exposing (..)

import Bytes
import Bytes.Decode
import Expect
import Fuzz
import Http
import Http.Constants
import Http.Extras
import Json.Decode
import Test exposing (Test, describe, fuzz, test)
import TestConstants as TC



-- Fuzzers


fuzzerHeader : Fuzz.Fuzzer (List ( String, String ))
fuzzerHeader =
    Fuzz.list <| Fuzz.tuple ( Fuzz.string, Fuzz.string )



{- BEGIN TESTS -}
-- REQUESTS


listToHeaders : Test
listToHeaders =
    describe "Http.Extras.listToHeaders"
        [ test "Manually created list" <|
            \_ ->
                Expect.equal
                    (Http.Extras.listToHeaders [ ( "Max-Forwards", "10" ), ( "Authorization", "Basic pw123" ) ])
                    [ Http.header "Max-Forwards" "10", Http.header "Authorization" "Basic pw123" ]

        -- The fuzz testing here is just re-implementing the function itself
        -- Thus it's not really needed, and fuzz testing is not used in the other tests
        -- Mostly just self-exploration of fuzz testing in Elm
        , fuzz fuzzerHeader "Fuzz List (String, String) " <|
            \listOfStringTuples ->
                Expect.equal (Http.Extras.listToHeaders listOfStringTuples) (List.map (\( field, value ) -> Http.header field value) listOfStringTuples)
        ]


listToQuery : Test
listToQuery =
    test "Http.Extras.listToQuery" <|
        \_ ->
            Expect.equal
                (Http.Extras.listToQuery [ ( "foo", "abc 123" ), ( "bar", "xyz" ) ])
                "?foo=abc%20123&bar=xyz"



-- RESPONSES
-- TRANSFORMERS


responseToString : Test
responseToString =
    describe "Http.Extras.responseToString"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.responseToString (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.responseToString Http.Timeout_) (Err Http.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.responseToString Http.NetworkError_) (Err Http.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToString (Http.BadStatus_ TC.badStatusMetadata TC.genericBadStringBody))
                    (Err (Http.BadStatus TC.badStatusMetadata.statusCode))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToString (Http.GoodStatus_ TC.goodStatusMetadata TC.genericGoodStringBody))
                    (Ok TC.genericGoodStringBody)
        ]


responseToJson : Test
responseToJson =
    describe "Http.Extras.responseToJson"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.responseToJson Json.Decode.int (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.responseToJson Json.Decode.int Http.Timeout_) (Err Http.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.responseToJson Json.Decode.int Http.NetworkError_) (Err Http.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToJson Json.Decode.int (Http.BadStatus_ TC.badStatusMetadata TC.genericBadStringBody))
                    (Err (Http.BadStatus TC.badStatusMetadata.statusCode))

        -- Various types of cases for good status based on JSON decoding
        -- Lack of metadata in all cases!
        , test "Good Status - JSON Decoding Failed - Invalid JSON" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToJson Json.Decode.int (Http.GoodStatus_ TC.goodStatusMetadata TC.genericGoodStringBody))
                    (Err (Http.BadBody "Problem with the given value:\n\n\"Here is some text in a response body.\"\n\nThis is not valid JSON! Unexpected token H in JSON at position 0"))
        , test "Good Status - JSON Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToJson TC.genericJsonDecoderFail (Http.GoodStatus_ TC.goodStatusMetadata TC.genericJsonBody))
                    (Err (Http.BadBody "Problem with the value at json.x:\n\n    3\n\nExpecting a STRING"))
        , test "Good Status - JSON Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToJson TC.genericJsonDecoder (Http.GoodStatus_ TC.goodStatusMetadata TC.genericJsonBody))
                    (Ok 3)
        ]


responseToBytes : Test
responseToBytes =
    describe "Http.Extras.responseToBytes"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.responseToBytes TC.genericBytesDecoder (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.responseToBytes TC.genericBytesDecoder Http.Timeout_) (Err Http.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.responseToBytes TC.genericBytesDecoder Http.NetworkError_) (Err Http.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToBytes TC.genericBytesDecoder (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Err (Http.BadStatus TC.badStatusMetadata.statusCode))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - Bytes Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToBytes (Bytes.Decode.float64 Bytes.BE) (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Err (Http.BadBody Http.Constants.bytesErrorMessage))
        , test "Good Status - Bytes Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToBytes TC.genericBytesDecoder (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.genericBytesIntValue)
        ]


responseToWhatever : Test
responseToWhatever =
    describe "Http.Extras.responseToWhatever"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.responseToWhatever (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.responseToWhatever Http.Timeout_) (Err Http.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.responseToWhatever Http.NetworkError_) (Err Http.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToWhatever (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Err (Http.BadStatus TC.badStatusMetadata.statusCode))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.responseToWhatever (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok ())
        ]



-- GETTERS


getUrl : Test
getUrl =
    describe "Http.Extras.getUrl"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.getUrl (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Constants.urlErrorMessage TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.getUrl Http.Timeout_) (Err Http.Constants.timeoutErrorMessage)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.getUrl Http.NetworkError_) (Err Http.Constants.networkErrorMessage)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getUrl (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Ok TC.badStatusMetadata.url)
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getUrl (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.goodStatusMetadata.url)
        ]


getStatusCode : Test
getStatusCode =
    describe "Http.Extras.getStatusCode"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.getStatusCode (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Constants.urlErrorMessage TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.getStatusCode Http.Timeout_) (Err Http.Constants.timeoutErrorMessage)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.getStatusCode Http.NetworkError_) (Err Http.Constants.networkErrorMessage)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getStatusCode (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Ok TC.badStatusMetadata.statusCode)
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getStatusCode (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.goodStatusMetadata.statusCode)
        ]


getStatusText : Test
getStatusText =
    describe "Http.Extras.getStatusText"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.getStatusText (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Constants.urlErrorMessage TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.getStatusText Http.Timeout_) (Err Http.Constants.timeoutErrorMessage)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.getStatusText Http.NetworkError_) (Err Http.Constants.networkErrorMessage)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getStatusText (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Ok TC.badStatusMetadata.statusText)
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getStatusText (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.goodStatusMetadata.statusText)
        ]


getHeaders : Test
getHeaders =
    describe "Http.Extras.getHeaders"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.getHeaders (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Constants.urlErrorMessage TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.getHeaders Http.Timeout_) (Err Http.Constants.timeoutErrorMessage)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.getHeaders Http.NetworkError_) (Err Http.Constants.networkErrorMessage)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getHeaders (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Ok TC.badStatusMetadata.headers)
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getHeaders (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.goodStatusMetadata.headers)
        ]


getMetadata : Test
getMetadata =
    describe "Http.Extras.getMetadata"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.getMetadata (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Constants.urlErrorMessage TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.getMetadata Http.Timeout_) (Err Http.Constants.timeoutErrorMessage)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.getMetadata Http.NetworkError_) (Err Http.Constants.networkErrorMessage)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getMetadata (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Ok TC.badStatusMetadata)
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getMetadata (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.goodStatusMetadata)
        ]


getBody : Test
getBody =
    describe "Http.Extras.getBody"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Extras.getBody (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Constants.urlErrorMessage TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Extras.getBody Http.Timeout_) (Err Http.Constants.timeoutErrorMessage)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Extras.getBody Http.NetworkError_) (Err Http.Constants.networkErrorMessage)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getBody (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Ok TC.genericBytesBody)
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Extras.getBody (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok TC.genericBytesBody)
        ]
