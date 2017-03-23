const express = require('express');
const bodyParser = require('body-parser');
const app = express();
const dpaReturn = require('./dpa-stat-return');

dpaReturn.run();

// Define API routes
// app.use('/api', bodyParser.json(), apolloExpress({ schema }));

// // Start server
// app.listen(4000, () => console.log('Now browse to localhost:4000/graphiql'));