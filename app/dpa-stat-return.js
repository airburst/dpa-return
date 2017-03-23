const excel = require('./excel/excel-service');
const template = './app/excel/templates/dpa-return.xlsx';
excel.read(template);

module.exports = {

    doDPA001: () => {

        let s = excel.firstSheetWithName('DPA001');

        excel.setCellValue(s, 'C5', 10);

        excel.setRange('B3:C4', []);

        // let r = excel.getRange('A2:D5');
        // console.log(r);

        excel.write();
    }

};
