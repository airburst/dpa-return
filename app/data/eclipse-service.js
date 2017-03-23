const pg = require('pg');
const config = require('./eclipse-config.js');
const pool = new pg.Pool(config);
const query = require('pg-query');
const sql = require('./sql');

query.connectionParameters = `postgres://${config.user}:${config.password}@${config.host}:${config.port}/${config.database}`;

// Success and error handlers
const handleError = (err) => {
    console.log(err || err.message)
    return [];                          // Ensure correct type
}
const onSuccess = (rows, result) => { return rows; }
const onError = (error) => { return handleError(error); }

// Public data methods
module.exports = {

    getUserByName: (params) => {
        var promise = query(sql.getUserByName(params.name));
        return promise.spread(onSuccess, onError);
    }

}
