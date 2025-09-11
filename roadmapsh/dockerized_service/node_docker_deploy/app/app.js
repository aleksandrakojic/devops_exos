require('dotenv').config();
const express = require('express');
const basicAuth = require('basic-auth');

const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello, world!');
});

app.get('/secret', (req, res) => {
  const user = basicAuth(req);
  const { USERNAME, PASSWORD, SECRET_MESSAGE } = process.env;

  if (!user || user.name !== USERNAME || user.pass !== PASSWORD) {
    res.set('WWW-Authenticate', 'Basic realm="Restricted Area"');
    return res.status(401).send('Access denied');
  }

  res.send(SECRET_MESSAGE);
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});