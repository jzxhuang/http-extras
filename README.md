# HTTP-Extras

**WORK IN PROGRESS:** This project is a work in progress. It is not stable and subject to change at any time.

HTTP-Extras helps you work with HTTP in Elm. It's made for version 2.0 of the [`Http`][http] package.

There are three separate modules that help you work with HTTP in different ways.

## Detailed

The default HTTP package discards the metadata and original body of an HTTP response, even though they are often useful.

For example, maybe your server returns a useful error message that you want to try and decode, or you want to access the header of the response on a successful request.

With this module, create HTTP requests that return more detailed responses - responses that keep useful information around instead of throwing them away!

## Extras

A collection of convenience and utility functions for creating HTTP requests and working with HTTP responses.

For example, there are helpers to...

* Convert a list of Strings to a query string or list of HTTP headers
* Extract information like the header, status code, url, etc. from an [`Http.Response`][httpResponse]
* Transform an [`Http.Response`][httpResponse] into a `Result`

## Mock

Easily mock the response of your API from within Elm. Don't bother setting up fake servers that mock responses.

Very useful for testing that your code is robust enough to handle any type of response, including edge cases like a request that results in a `Timeout`. Mock responses locally without any hassle.

## Example

Here's a complete example of how you might use all the modules in this package together. For more detailed examples of each module, see the module's documentation!

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
        { url = "https://api.giphy.com/v1/gifs/random" ++ Http.Extras.listToQuery queries
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

* We use [`Detailed`](/Http-Detailed) to create HTTP requests that return more detailed responses. In our `update` function, you can access these extra details like the metadata and use them as needed.
* The GIF request uses [`Extras`](/Http-Extras) to build a request that requires a query string
* The Items request uses [`Mock`](/Http-Mock) to mock a `Timeout` response.

## Contributing

Feedback and contributions are very welcome! Open an issue or pull request on Github as appropriate.

## License

HTTP-Extras is available under the BSD 3-Clause License. See LICENSE on the Github repo for details.

[http]: https://package.elm-lang.org/packages/elm/http/2.0.0
[httpResponse]: https://package.elm-lang.org/packages/elm/http/2.0.0/Http#Response