const Transforms = require('./data/transforms');
const excel = require('./excel/excel-service');

let transforms = new Transforms();

const handleError = (e) => {
    console.log(e);
    return null;
}

const getData = () => {
    return transforms.load()
        .then(results => { return results; })
        .catch(handleError);
}

const processData = () => {
    // The run sequence of actions
    excel.read('./app/excel/templates/dpa-return.xlsx');
    let data = transforms.data;
    console.log(data);
    
    // etc..

    excel.write();
}

// Do the run sequence (async, once data is returned)
module.exports = {
    run: () => { getData().then(processData).catch(handleError); }
};