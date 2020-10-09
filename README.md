# Token Authentication
This sample project demostrates how to handle Token Based Authentication with ReactiveAPI.

## What you will find
* `Demo401` is a simple iOS app which interacts with the demo server
* `server` contains a node.js example server with the endpoints needed by the demo app
* `server-requests` as a series of shell scripts to interact with the server from CLI


## How to make it work
* Be sure to have node.js installed on your mac. If not, get from here: https://nodejs.org/en/download/
* open a terminal, go to the `server` directory and execute: `npm i && npm start`. Don't close the terminal, you need to keep it open to make the server run and see its logs
    * next times, to start the server it's sufficient to execute `npm start`
    * to stop the server, press `Control + C`
* open the Demo401 project from Xcode
* `Command + R` and have fun!

## How it works
`ReactiveAPI` borrows the concepts of `Interceptor` and `Authenticator` from [OkHttp](https://square.github.io/okhttp/) which makes working with token based authentication mechanism a breeze.

### Interceptor
It can enrich requests to the server, by adding headers and parameters. When added to a ReactiveAPI instance, it is automatically called on each request. In this example it will be used to automatically add the saved token to each authenticated request.

### Authenticator
It is called everytime there's an HTTP error. It gives you the possibility to try to recover errors. In this example it will be used to try to recover `HTTP 401 Unauthorized` errors by making a token renew request. If that succeeds, the original API call which failed will be automatically retried by ReactiveAPI.

For example, consider this flow:
* perform `/login` and save a token which expires in 5 minutes
* perform `/some-authenticated-api` after the token is expired. This will happen
    * `/some-authenticated-api` will return a 401
    * Authenticator will be called, which in turn will make a request to `/refresh-token`
    * If that succeeds, the original call to `/some-authenticated-api` will be automatically retried, otherwise you will get a permanent `401 Unauthorized` HTTP error

We consider working software much better than comprehensive documentation, so get your hands dirty, clone the project and try it yourself! Most of all, have fun!
