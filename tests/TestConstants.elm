module TestConstants exposing (..)

import Bytes
import Bytes.Decode
import Bytes.Encode
import Dict
import Http
import Json.Decode



{-
   Constants for testing purposes
-}
-- Generic values


genericBadUrl : String
genericBadUrl =
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
    Bytes.Encode.encode genericBytesEncoder



-- JSON Decoders


genericJsonDecoder : Json.Decode.Decoder Int
genericJsonDecoder =
    Json.Decode.field "x" Json.Decode.int


genericJsonDecoderFail : Json.Decode.Decoder String
genericJsonDecoderFail =
    Json.Decode.field "x" Json.Decode.string



-- Bytes Encoders/Decoders


genericBytesIntValue : Int
genericBytesIntValue =
    7


genericBytesEncoder : Bytes.Encode.Encoder
genericBytesEncoder =
    Bytes.Encode.unsignedInt16 Bytes.BE genericBytesIntValue


genericBytesDecoder : Bytes.Decode.Decoder Int
genericBytesDecoder =
    Bytes.Decode.unsignedInt16 Bytes.BE
