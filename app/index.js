// const express = require('express');
// const bodyParser = require('body-parser');
// const app = express();
const ExcelService = require('./excel/ExcelService');
const excel = new ExcelService();

const data = require('./data/sqlData.json');

excel.read('./app/excel/templates/dpa-template.xlsx')
    .then((w) => {
        excel.loadTableData(data);
        excel.write();
    })
    .catch(err => console.log(err));
