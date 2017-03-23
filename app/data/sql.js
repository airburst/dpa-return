/* Collection of PostgreSQL queries.  Use meaningful names
   that you can refer to in data service functions. */
module.exports = {

    getUserByName: (name) => {
        return
        `SELECT * FROM table
            WHERE LOWER(name) LIKE LOWER('%${name}%')`;
    }

};

// let whereClauses = [];
// if (params && params.firstNames) {
//     whereClauses.push(`LOWER(firstname) LIKE LOWER('%${params.firstNames}%')`);
// }
// if (params && params.surname) {
//     whereClauses.push(`LOWER(surname) LIKE LOWER('%${params.surname}%')`);
// }
// let sql = `SELECT ${makeFieldList(fields.person)} FROM people`;
// if (whereClauses.length > 0) { sql += ` WHERE ${whereClauses.join(' AND ')}`; }