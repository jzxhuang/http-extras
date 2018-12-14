# HTTP-Extras

**WORK IN PROGRESS:** This project is a work in progress. It is not stable and subject to change at any time.

HTTP-Extras helps you work with HTTP in Elm.

It's made to be used with version 2.0 of the [`Http`][http] package.

## Detailed

The default HTTP package discards the metadata and original body of an HTTP response, even though they are often useful.

For example, maybe your server returns a useful error message that you want to try and decode, or you want to access the header of the response on a successful request.

This module helps you create HTTP requests that return more detailed responses which keep this useful information around.

## Extras

A collection of convenience and utility functions for creating HTTP requests and working with an HTTP response.

For example, there are helpers to...

* Easily generate a query string or list of HTTP headers
* Extract information like the header, status code, url, etc. from an [`Http.Response`][httpResponse]
* Transform an [`Http.Response`][httpResponse] into a `Result`

## Mock

Easily mock an HTTP response directly from within Elm. Mock your API locally without having to deal with setting up a fake HTTP server.

Very useful for testing that your code is robust enough to handle any type of response, including edge cases like a request that results in a `Timeout`.

## Example

Here's a complete example of how you might use all the modules in this package together to send HTTP requests and handle the responses.

```elm
import Http
import Http.Detailed
import Http.Extras
import Http.Mock
import Json.Decode exposing (Decoder, field, string, list)


type Msg
    = GotGif (Result (Http.Detailed.Error String) ( String, Http.Metadata ))
    | GotItems (Result (Http.Detailed.Error String) ( List String, Http.Metadata ))



-- Build a request with query parameters and a detailed response


getRandomCatGif : List ( String, String ) -> Cmd Msg
getRandomCatGif queries =
    Http.get
        { url = "https://api.giphy.com/v1/gifs/random" ++ Http.Extras.generateQueryString queries
        , expect = Http.Detailed.expectJson GotGif gifDecoder
        }



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
                Ok ( gif, metadata ) ->
                    -- Success! Do something with the metadata if you need

                Err error ->
                    case error of
                        Http.Detailed.BadStatus metadata body statusCode ->
                            -- Maybe the error message is useful and you want to try and decode the body

                        ...

        GotItems detailedResponse ->
            case detailedResponse of
                Ok ( items, metadata ) ->
                    -- Success! Do something with the metadata if you need

                Err error ->
                    case error of
                        Http.Detailed.Timeout ->
                            -- We mock a Timeout response - make sure your code handles this case correctly!

                        ...

        ...

```

In this example:

* We use [`Detailed`](/Http-Detailed) to create requests with more detailed responses. In our `update` function, you can access these extra details like the metadata and use them as needed.
* The GIF request uses [`Extras`](/Http-Extras) to build a request that requires a query string
* The Items request uses [`Mock`](/Http-Mock) to mock a `Timeout` response.

## Contributing

Feedback and contributions are very welcome! Open an issue or pull request on Github as appropriate. If you're adding a new feature, make sure to give a use case demonstrating how it's useful.

## License

TODO -- BSD-3

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response