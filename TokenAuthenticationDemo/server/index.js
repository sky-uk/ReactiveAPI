var express = require('express');
var uuid4 = require('uuid4');
var app = express();

const user = {
    username: "user",
    password: "password"
}

var tokens = {
    shortLivedToken: "",
    renewToken: ""
}

var valid = false

function refreshTokens(force) {
    if (tokens.shortLivedToken === "" || tokens.renewToken === "" || force || !valid) {
        console.log("Refreshing tokens!")
        tokens.shortLivedToken = uuid4()
        tokens.renewToken = uuid4()
        valid = true
    }
}

app.use(express.json());

app.post('/login', (req, res) => {
    if ('username' in req.body && 'password' in req.body) {
        if (req.body.username === user.username && req.body.password === user.password) {
            refreshTokens(false)
            console.log("/login - Login succeeded!")
            res.status(200).json(tokens)
        } else {
            console.log("/login - Invalid username or password")
            res.status(403).json({
                error: "Invalid username or password"
            })
        }
    } else {
        console.log("/login - Invalid request")
        console.log(req.body)
        res.status(400).json({
            error: "Invalid request"
        })
    }
})

app.get('/invalidate', (req, res) => {
    console.log("/invalidate - Succeeded!")
    valid = false
    res.send('Successfully invalidated tokens');
});

app.post('/renewToken', (req, res) => {
    if ('shortLivedToken' in req.body && 'renewToken' in req.body) {
        if (req.body.shortLivedToken === tokens.shortLivedToken && req.body.renewToken === tokens.renewToken) {
            refreshTokens(true)
            console.log(`/renewToken - Token refresh succeeded! New tokens: ${JSON.stringify(tokens)}`)
            res.status(200).json(tokens)
        } else {
            console.log("/renewToken - Token is invalid")
            res.status(401).json({
                error: "Invalid tokens"
            })
        }
    } else {
        console.log("/renewToken - Invalid request")
        res.status(400).json({
            error: "Invalid request"
        })
    }
})

app.get('/version', (req, res) => {
    if (req.header('token') === tokens.shortLivedToken && valid) {
        console.log("/version - Success!")
        res.status(200).json({
            major: 1,
            minor: 0,
            patch: 0
        })
    } else {
        console.log("/version - Not authenticated! headers: ")
        console.log(req.headers)
        res.status(401).json({
            error: "Unauthenticated"
        })
    }
});

app.listen(3000, () => {
  console.log('Example server listening on port 3000!');
});
