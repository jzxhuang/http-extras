module Detailed exposing (..)

import Bytes
import Bytes.Decode
import Expect
import Http
import Http.Constants
import Http.Detailed
import Json.Decode
import Test exposing (Test, describe, test)
import TestConstants as TC



-- TRANSFORMERS - TUPLE


responseToString : Test
responseToString =
    describe "Http.Detailed.responseToString"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToString (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToString Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToString Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToString (Http.BadStatus_ TC.badStatusMetadata TC.genericBadStringBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBadStringBody))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToString (Http.GoodStatus_ TC.goodStatusMetadata TC.genericGoodStringBody))
                    (Ok ( TC.goodStatusMetadata, TC.genericGoodStringBody ))
        ]


responseToJson : Test
responseToJson =
    describe "Http.Detailed.responseToJson"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJson Json.Decode.int (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJson Json.Decode.int Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJson Json.Decode.int Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson Json.Decode.int (Http.BadStatus_ TC.badStatusMetadata TC.genericBadStringBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBadStringBody))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - JSON Decoding Failed - Invalid JSON" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson Json.Decode.int (Http.GoodStatus_ TC.goodStatusMetadata TC.genericGoodStringBody))
                    (Err (Http.Detailed.BadBody TC.goodStatusMetadata TC.genericGoodStringBody "Problem with the given value:\n\n\"Here is some text in a response body.\"\n\nThis is not valid JSON! Unexpected token H in JSON at position 0"))
        , test "Good Status - JSON Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson TC.genericJsonDecoderFail (Http.GoodStatus_ TC.goodStatusMetadata TC.genericJsonBody))
                    (Err (Http.Detailed.BadBody TC.goodStatusMetadata TC.genericJsonBody "Problem with the value at json.x:\n\n    3\n\nExpecting a STRING"))
        , test "Good Status - JSON Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson TC.genericJsonDecoder (Http.GoodStatus_ TC.goodStatusMetadata TC.genericJsonBody))
                    (Ok ( TC.goodStatusMetadata, 3 ))
        ]


responseToBytes : Test
responseToBytes =
    describe "Http.Detailed.responseToBytes"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytes TC.genericBytesDecoder (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytes TC.genericBytesDecoder Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytes TC.genericBytesDecoder Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytes TC.genericBytesDecoder (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBytesBody))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - Bytes Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytes (Bytes.Decode.float64 Bytes.BE) (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Err (Http.Detailed.BadBody TC.goodStatusMetadata TC.genericBytesBody Http.Constants.bytesErrorMessage))
        , test "Good Status - Bytes Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytes TC.genericBytesDecoder (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok ( TC.goodStatusMetadata, TC.genericBytesIntValue ))
        ]



-- TRANSFORMERS - RECORD


responseToStringRecord : Test
responseToStringRecord =
    describe "Http.Detailed.responseToStringRecord"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToStringRecord (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToStringRecord Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToStringRecord Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToStringRecord (Http.BadStatus_ TC.badStatusMetadata TC.genericBadStringBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBadStringBody))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToStringRecord (Http.GoodStatus_ TC.goodStatusMetadata TC.genericGoodStringBody))
                    (Ok (Http.Detailed.Success TC.goodStatusMetadata TC.genericGoodStringBody))
        ]


responseToJsonRecord : Test
responseToJsonRecord =
    describe "Http.Detailed.responseToJsonRecord"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJsonRecord Json.Decode.int (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJsonRecord Json.Decode.int Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJsonRecord Json.Decode.int Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord Json.Decode.int (Http.BadStatus_ TC.badStatusMetadata TC.genericBadStringBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBadStringBody))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - JSON Decoding Failed - Invalid JSON" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord Json.Decode.int (Http.GoodStatus_ TC.goodStatusMetadata TC.genericGoodStringBody))
                    (Err (Http.Detailed.BadBody TC.goodStatusMetadata TC.genericGoodStringBody "Problem with the given value:\n\n\"Here is some text in a response body.\"\n\nThis is not valid JSON! Unexpected token H in JSON at position 0"))
        , test "Good Status - JSON Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord TC.genericJsonDecoderFail (Http.GoodStatus_ TC.goodStatusMetadata TC.genericJsonBody))
                    (Err (Http.Detailed.BadBody TC.goodStatusMetadata TC.genericJsonBody "Problem with the value at json.x:\n\n    3\n\nExpecting a STRING"))
        , test "Good Status - JSON Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord TC.genericJsonDecoder (Http.GoodStatus_ TC.goodStatusMetadata TC.genericJsonBody))
                    (Ok (Http.Detailed.Success TC.goodStatusMetadata 3))
        ]


responseToBytesRecord : Test
responseToBytesRecord =
    describe "Http.Detailed.responseToBytesRecord"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytesRecord TC.genericBytesDecoder (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytesRecord TC.genericBytesDecoder Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytesRecord TC.genericBytesDecoder Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytesRecord TC.genericBytesDecoder (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBytesBody))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - Bytes Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytesRecord (Bytes.Decode.float64 Bytes.BE) (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Err (Http.Detailed.BadBody TC.goodStatusMetadata TC.genericBytesBody Http.Constants.bytesErrorMessage))
        , test "Good Status - Bytes Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytesRecord TC.genericBytesDecoder (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok (Http.Detailed.Success TC.goodStatusMetadata TC.genericBytesIntValue))
        ]



-- WHATEVER


responseToWhatever : Test
responseToWhatever =
    describe "Http.Detailed.responseToWhatever"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToWhatever (Http.BadUrl_ TC.genericBadUrl)) (Err (Http.Detailed.BadUrl TC.genericBadUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToWhatever Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToWhatever Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToWhatever (Http.BadStatus_ TC.badStatusMetadata TC.genericBytesBody))
                    (Err (Http.Detailed.BadStatus TC.badStatusMetadata TC.genericBytesBody))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToWhatever (Http.GoodStatus_ TC.goodStatusMetadata TC.genericBytesBody))
                    (Ok ())
        ]
