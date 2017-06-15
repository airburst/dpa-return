// const express = require('express');
// const bodyParser = require('body-parser');
// const app = express();
const ExcelService = require('./excel/ExcelService');
const excel = new ExcelService();

excel.read('./app/excel/templates/dpa-template.xlsx')
    .then((w) => {
        // Write some data
        writeDPA1();

        // Write the workbook to file
        excel.write();
    })
    .catch(err => console.log(err));

// Produce a write function for each worksheet
writeDPA1 = () => {
    const sheet = 'DPA001 - Activity Data';
    excel.writeValue(sheet, 'C5', 230);
    excel.writeValue(sheet, 'C6', 24);
    excel.writeValue(sheet, 'D5', 25);
    excel.writeValue(sheet, 'D6', 26);
}