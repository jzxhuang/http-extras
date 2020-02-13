module Http.Constants exposing (..)

{-
   This file holds constant declarations
   It is not exposed as part of the package!

   Constants used for testing are not declared here.
-}


urlErrorMessage : String -> String
urlErrorMessage url =
    "Bad Url: " ++ url


timeoutErrorMessage : String
timeoutErrorMessage =
    "Timeout"


networkErrorMessage : String
networkErrorMessage =
    "Network Error"


badStatusCodeErrorMessage : Int -> String
badStatusCodeErrorMessage code =
    "Bad status: " ++ String.fromInt code


bytesErrorMessage : String
bytesErrorMessage =
    "Error decoding bytes"
