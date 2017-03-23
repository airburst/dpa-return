const Transform = require('./data/transforms');
const excel = require('./excel/excel-service');

let transform = new Transform();

const handleError = (e) => {
    console.log(e);
    return null;
}

const getData = () => {
    return transform.load()
        .then(results => { return results; })
        .catch(handleError);
}

const processData = () => {
    // The run sequence of actions
    excel.read('./app/excel/templates/dpa-return.xlsx');
    let count = transform.query('age gt 65').length;
    console.log(count);

    let data = transform.query('dparequestedstartdate ge 2016-10-01')
    console.log(transform.count());

    // etc..

    // excel.write();
}

// Do the run sequence (async, once data is returned)
module.exports = {
    run: () => { getData().then(processData).catch(handleError); }
};