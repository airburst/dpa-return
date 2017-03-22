const excel = require('./excel/ExcelServiceXLSX');
const template = './app/excel/templates/dpa-return-unprotected.xlsx';
excel.read(template);

// We need to ensure that sheets are written in the correct order
// const sheets = [
//     'Cover',
//     'Version control',
//     'DPA001 - Activity Data',
//     'DPA002 - Finance Data',
//     'DPA003 - New Requests for DPAs',
//     'DPA004 - Nature of DPAs',
//     'DPA005 - Recovery of DPA',
//     'DPA006 - DPA Written Off'
// ];
// let order = [];

module.exports = {

    doDPA001: () => {

        let s = excel.firstSheetWithName('DPA001');

        excel.setCellValue(s, 'C5', 10);

        excel.write();

        // excel.read(template)
        //     .then(w => {
        //         w.eachSheet(sheet => order.push(sheets.indexOf(sheet.name)));
        //         // console.log(order);

        //         // let w = excel.reorderSheets(w, order);

        //         console.log(excel.getCellValue(w, 'DPA001 - Activity Data', 'C3'));

        //         excel.setCellValue(w, 'DPA001 - Activity Data', 'C5', 10);

        //         // Write the results to file
        //         excel.write(w, 'out.xlsx')
        //             .then(() => console.log('Written'))
        //             .catch(err => console.log('Error writing file', err));
        //     })
        //     .catch(err => console.log('Error reading template', err));
    }

};
