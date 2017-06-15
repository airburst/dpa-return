const express = require('express');
const bodyParser = require('body-parser');
const app = express();
// const dpaReturn = require('./dpa-stat-return');

// dpaReturn.run();

const Excel = require('./excel/exceljs-service');
const excel = new Excel();

excel.read('./app/excel/templates/dpa-template.xlsx')
    .then(workbook => excel.write())
    .catch(err => console.log(err));