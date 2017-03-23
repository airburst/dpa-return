const excel = require('./excel/excel-service');
const template = './app/excel/templates/dpa-return.xlsx';

const doDPA001 = () => {
    let s = excel.firstSheetWithName('DPA001');

    let data = [
        [10, 20],
        [30, 40],
        [50, 60],
        [70, 80]
    ];

    excel.setRange(s, 'C5:D8', data);
}

// Run script
const run = () => {
    excel.read(template);

    doDPA001();
    // etc.

    excel.write();
};


module.exports = {
    run: run
};