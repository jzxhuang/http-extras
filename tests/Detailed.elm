module Detailed exposing (..)

import Bytes
import Bytes.Decode
import Bytes.Encode
import Constants
import Dict
import Expect
import Http
import Http.Detailed
import Json.Decode
import Test exposing (Test, describe, test)



-- CONSTANTS (test-specific)
-- Generic values


badUrl : String
badUrl =
    "http://bad-url.com"


genericUrl : String
genericUrl =
    "https://package.elm-lang.org/packages/jzxhuang/http-extras/latest/"


genericHeaders : Dict.Dict String String
genericHeaders =
    Dict.singleton "Max-Forwards" "10"



-- Metadata


badStatusMetadata : Http.Metadata
badStatusMetadata =
    { url = genericUrl, statusCode = 500, statusText = "Internal Server Error", headers = genericHeaders }


goodStatusMetadata : Http.Metadata
goodStatusMetadata =
    { url = genericUrl, statusCode = 200, statusText = "OK", headers = genericHeaders }



-- Bodies


genericGoodStringBody : String
genericGoodStringBody =
    "Here is some text in a response body."


genericBadStringBody : String
genericBadStringBody =
    "A bad body."


genericJsonBody : String
genericJsonBody =
    "{ \"x\": 3 }"


genericBytesBody : Bytes.Bytes
genericBytesBody =
    Bytes.Encode.encode (Bytes.Encode.unsignedInt16 Bytes.BE 7)



-- JSON Decoders


genericJsonDecoder : Json.Decode.Decoder Int
genericJsonDecoder =
    Json.Decode.field "x" Json.Decode.int


genericJsonDecoderFail : Json.Decode.Decoder String
genericJsonDecoderFail =
    Json.Decode.field "x" Json.Decode.string



-- TRANSFORMERS - TUPLE


transformersTupleResponseToString : Test
transformersTupleResponseToString =
    describe "Transformers (Tuple): responseToString"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToString (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToString Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToString Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToString (Http.BadStatus_ badStatusMetadata genericBadStringBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBadStringBody))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToString (Http.GoodStatus_ goodStatusMetadata genericGoodStringBody))
                    (Ok ( goodStatusMetadata, genericGoodStringBody ))
        ]


transformersTupleResponseToJson : Test
transformersTupleResponseToJson =
    describe "Transformers (Tuple): responseToJson"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJson Json.Decode.int (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJson Json.Decode.int Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJson Json.Decode.int Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson Json.Decode.int (Http.BadStatus_ badStatusMetadata genericBadStringBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBadStringBody))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - JSON Decoding Failed - Invalid JSON" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson Json.Decode.int (Http.GoodStatus_ goodStatusMetadata genericGoodStringBody))
                    (Err (Http.Detailed.BadBody goodStatusMetadata genericGoodStringBody "Problem with the given value:\n\n\"Here is some text in a response body.\"\n\nThis is not valid JSON! Unexpected token H in JSON at position 0"))
        , test "Good Status - JSON Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson genericJsonDecoderFail (Http.GoodStatus_ goodStatusMetadata genericJsonBody))
                    (Err (Http.Detailed.BadBody goodStatusMetadata genericJsonBody "Problem with the value at json.x:\n\n    3\n\nExpecting a STRING"))
        , test "Good Status - JSON Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJson genericJsonDecoder (Http.GoodStatus_ goodStatusMetadata genericJsonBody))
                    (Ok ( goodStatusMetadata, 3 ))
        ]


transformersTupleResponseToBytes : Test
transformersTupleResponseToBytes =
    describe "Transformers (Tuple): responseToBytes"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytes (Bytes.Decode.unsignedInt16 Bytes.BE) (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytes (Bytes.Decode.unsignedInt16 Bytes.BE) Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytes (Bytes.Decode.unsignedInt16 Bytes.BE) Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytes (Bytes.Decode.unsignedInt16 Bytes.BE) (Http.BadStatus_ badStatusMetadata genericBytesBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBytesBody))

        -- Various types of cases for good status based on JSON decoding
        -- Can be fuzzed?
        , test "Good Status - Bytes Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytes (Bytes.Decode.float64 Bytes.BE) (Http.GoodStatus_ goodStatusMetadata genericBytesBody))
                    (Err (Http.Detailed.BadBody goodStatusMetadata genericBytesBody Constants.bytesErrorMessage))

        -- Can be fuzzed?
        , test "Good Status - Bytes Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytes (Bytes.Decode.unsignedInt16 Bytes.BE) (Http.GoodStatus_ goodStatusMetadata genericBytesBody))
                    (Ok ( goodStatusMetadata, 7 ))
        ]



-- TRANSFORMERS - RECORD


transformersRecordResponseToString : Test
transformersRecordResponseToString =
    describe "Transformers (Record): responseToString"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToStringRecord (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToStringRecord Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToStringRecord Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToStringRecord (Http.BadStatus_ badStatusMetadata genericBadStringBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBadStringBody))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToStringRecord (Http.GoodStatus_ goodStatusMetadata genericGoodStringBody))
                    (Ok (Http.Detailed.Success goodStatusMetadata genericGoodStringBody))
        ]


transformersRecordResponseToJson : Test
transformersRecordResponseToJson =
    describe "Transformers (Record): responseToJson"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJsonRecord Json.Decode.int (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJsonRecord Json.Decode.int Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToJsonRecord Json.Decode.int Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord Json.Decode.int (Http.BadStatus_ badStatusMetadata genericBadStringBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBadStringBody))

        -- Various types of cases for good status based on JSON decoding
        , test "Good Status - JSON Decoding Failed - Invalid JSON" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord Json.Decode.int (Http.GoodStatus_ goodStatusMetadata genericGoodStringBody))
                    (Err (Http.Detailed.BadBody goodStatusMetadata genericGoodStringBody "Problem with the given value:\n\n\"Here is some text in a response body.\"\n\nThis is not valid JSON! Unexpected token H in JSON at position 0"))
        , test "Good Status - JSON Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord genericJsonDecoderFail (Http.GoodStatus_ goodStatusMetadata genericJsonBody))
                    (Err (Http.Detailed.BadBody goodStatusMetadata genericJsonBody "Problem with the value at json.x:\n\n    3\n\nExpecting a STRING"))
        , test "Good Status - JSON Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToJsonRecord genericJsonDecoder (Http.GoodStatus_ goodStatusMetadata genericJsonBody))
                    (Ok (Http.Detailed.Success goodStatusMetadata 3))
        ]


transformersRecordResponseToBytes : Test
transformersRecordResponseToBytes =
    describe "Transformers (Record): responseToBytes"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytesRecord (Bytes.Decode.unsignedInt16 Bytes.BE) (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytesRecord (Bytes.Decode.unsignedInt16 Bytes.BE) Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToBytesRecord (Bytes.Decode.unsignedInt16 Bytes.BE) Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytesRecord (Bytes.Decode.unsignedInt16 Bytes.BE) (Http.BadStatus_ badStatusMetadata genericBytesBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBytesBody))

        -- Various types of cases for good status based on JSON decoding
        -- Can be fuzzed?
        , test "Good Status - Bytes Decoding Failed" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytesRecord (Bytes.Decode.float64 Bytes.BE) (Http.GoodStatus_ goodStatusMetadata genericBytesBody))
                    (Err (Http.Detailed.BadBody goodStatusMetadata genericBytesBody Constants.bytesErrorMessage))

        -- Can be fuzzed?
        , test "Good Status - Bytes Decoding Successful" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToBytesRecord (Bytes.Decode.unsignedInt16 Bytes.BE) (Http.GoodStatus_ goodStatusMetadata genericBytesBody))
                    (Ok (Http.Detailed.Success goodStatusMetadata 7))
        ]



-- WHATEVER


transformersResponseToWhatever : Test
transformersResponseToWhatever =
    describe "Transformers: responseToWhatever"
        [ test "Bad URL" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToWhatever (Http.BadUrl_ badUrl)) (Err (Http.Detailed.BadUrl badUrl))
        , test "Timeout" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToWhatever Http.Timeout_) (Err Http.Detailed.Timeout)
        , test "Network Error" <|
            \_ ->
                Expect.equal (Http.Detailed.responseToWhatever Http.NetworkError_) (Err Http.Detailed.NetworkError)
        , test "Bad Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToWhatever (Http.BadStatus_ badStatusMetadata genericBytesBody))
                    (Err (Http.Detailed.BadStatus badStatusMetadata genericBytesBody))
        , test "Good Status" <|
            \_ ->
                Expect.equal
                    (Http.Detailed.responseToWhatever (Http.GoodStatus_ goodStatusMetadata genericBytesBody))
                    (Ok ())
        ]
