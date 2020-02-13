# http-extras

Three modules to help you work with HTTP in Elm. More detailed responses, convenience functions, and API mocking.

Made for use with version **2.0+** of [`elm/http`][http].

## Detailed

[`elm/http`][http] discards the metadata and original body of an HTTP response, even though they are often useful.

For example, maybe your server returns a useful error message that you want to try and decode, or store an auth token in the header of a response.

This module lets you create HTTP requests that return more detailed responses - responses that keep useful information around instead of throwing them away!

_I wrote a [guide explaining how to extract detailed information from HTTP responses in Elm,][Going Beyond 200 OK] both with and without this package. Giving it a read might help you better understand the motivation and use cases behind this module!_

## Extras

A collection of convenience and utility functions for creating HTTP requests and working with HTTP responses.

For example, there are helpers to...

* Convert a `List ( String, String )` to a percent-encoded query string or `List Http.Header`
* Extract information like the header, status code, url, etc. from an [`Http.Response`][httpResponse]
* Transform an [`Http.Response`][httpResponse] into the `Result` used by [`elm/http`][http].

## Mock

Easily mock the response of your API from within Elm. Don't bother setting up fake servers that mock responses.

Very useful for testing your code. Make sure it's robust enough to handle any type of response, including edge cases like a request that results in a `Timeout`.

_I wrote a [guide discussing HTTP mocking in Elm][Oh the mockery], both with and without this package. Giving it a read might help you better understand the motivation and use cases behind this module!_

## Example

Here's a complete example of how you might use all the modules in this package together. See each module's documentation for more specific examples!

```elm
import Http
import Http.Detailed
import Http.Extras
import Http.Mock
import Json.Decode exposing (Decoder, field, string, list)


type Msg
    = GotGif (Result (Http.Detailed.Error String) ( Http.Metadata, String ))
    | GotItems (Result (Http.Detailed.Error String) ( Http.Metadata, List String ))


-- Build a request with query parameters and a detailed response


getRandomCatGif : List ( String, String ) -> Cmd Msg
getRandomCatGif queries =
    Http.get
        { url = "https://api.giphy.com/v1/gifs/random" ++ Http.Extras.listToQuery queries
        , expect = Http.Detailed.expectJson GotGif gifDecoder


-- Mock a timeout response


fetchItemsMockingTimeout : Cmd Msg
fetchItemsMockingTimeout =
    Http.post
        { url = "https://fakeurl.com/items.json"
        , body = Http.emptyBody
        , expect =
            Http.Mock.expectStringResponse Http.Timeout_ GotItems <|
                Http.Detailed.responseToJson itemsDecoder
        }


-- Decoders


gifDecoder : Decoder String
gifDecoder =
    field "data" (field "image_url" string)


itemsDecoder : Decoder (List String)
itemsDecoder =
    list (field "name" string)


-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotGif detailedResponse ->
            case detailedResponse of
                Ok ( metadata, gif ) ->
                    -- Success! Do something with the metadata if you need

                Err error ->
                    case error of
                        Http.Detailed.BadStatus metadata body ->
                            -- Maybe the error message is useful and you want to try and decode the body

                        ...

        GotItems detailedResponse ->
            case detailedResponse of
                Ok ( metadata, items ) ->
                    -- Success! Do something with the metadata if you need

                Err error ->
                    case error of
                        Http.Detailed.Timeout ->
                            -- We mock a Timeout response - make sure your code handles this case correctly!

                        ...

        ...

```

In this example:

* We use [`Detailed`](/Http-Detailed) to create HTTP requests that return more detailed responses. In our `update` function, you can access these extra details like the metadata and use them as needed.
* The GIF request uses [`Extras`](/Http-Extras) to build a request with a query string.
* The Items request uses [`Mock`](/Http-Mock) to mock a `Timeout` response.

## Contributing

Feedback and contributions are very welcome! Open an issue or pull request on Github as appropriate.

## License

HTTP-Extras is available under the [BSD-3-Clause License][bsd]. See LICENSE on the Github repo for details.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response
[bsd]: https://opensource.org/licenses/BSD-3-Clause
[Going Beyond 200 OK]: https://medium.com/@jzxhuang/going-beyond-200-ok-a-guide-to-detailed-http-responses-in-elm-6ddd02322e
[Oh the Mockery]: https://medium.com/@jzxhuang/oh-the-mockery-a-guide-to-http-mocking-in-elm-f625c2a56c9f
