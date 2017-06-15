const Excel = require('exceljs');

class ExcelJS {

    constructor() {
        this.workbook = new Excel.Workbook();
    }

    read(filename) {
        return this.workbook.xlsx.readFile(filename);
    }

    write(filename) {
        const f = filename || this.makeFilename();
        return this.workbook.xlsx.writeFile(f);
    }

    makeFilename() {
        return new Date().toISOString().slice(0, 10) + '.xlsx';
    };

}

module.exports = ExcelJS;

// pipe from stream 
// var workbook = new Excel.Workbook();
// stream.pipe(workbook.xlsx.createInputStream());