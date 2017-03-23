const eclipse = require('./data/eclipse-service');
const excel = require('./excel/excel-service');
const template = './app/excel/templates/dpa-return.xlsx';

const doDPA001 = () => {
    let data = eclipse.getTestData()
        .then(results => {
            console.log(results);

            // new excel.sheet('DPA001')
            //     .setData('C5:D8', data)
            //     .setData('C14:D17', data);
        })
        .catch(err => console.log(err));
}

// Run script
const run = () => {
    excel.read(template);

    doDPA001();
    // etc.

    // excel.write();
};


module.exports = {
    run: run
};