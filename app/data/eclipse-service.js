const pg = require('pg');
const config = require('./eclipse-config.js');
const pool = new pg.Pool(config);
const query = require('pg-query');
const sql = require('./sql');

const mock = require('./mock.json');

query.connectionParameters = `postgres://${config.user}:${config.password}@${config.host}:${config.port}/${config.database}`;

// Success and error handlers
const handleError = (err) => {
    console.log(err || err.message);
    return [];
}
const onSuccess = (rows, result) => { return rows; }
const onError = (error) => { return handleError(error); }

// Methods 
const getTestData = () => {
    var promise = query(sql.getTestData);
    return promise.spread(onSuccess, onError);
};

const mockData = () => {
    return new Promise((resolve, reject) => resolve(mock));
}

// Public data methods
module.exports = {
    // getTestData: getTestData
    getTestData: mockData
};
