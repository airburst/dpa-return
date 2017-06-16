const Excel = require('exceljs');
const sheetOrder = [
    'Cover',
    'DATA',
    'Version control',
    'DPA001 - Activity Data',
    'DPA002 - Finance Data',
    'DPA003 - New Requests for DPAs',
    'DPA004 - Nature of DPAs',
    'DPA005 - Recovery of DPA',
    'DPA006 - DPA Written Off'
];

class ExcelService {

    constructor() {
        this.workbook = new Excel.Workbook();
        this.setProperties();
    }

    setProperties() {
        this.workbook.creator = 'OLM Systems';
        this.workbook.created = new Date();
    }

    read(filename) {
        return this.workbook.xlsx.readFile(filename);
    }

    listSheets(workbook) {
        this.workbook.eachSheet((sheet, id) => (console.log(id, sheet.name)));
    }

    loadJsonData(data) {
        data.map(record => {
            if (this.workbook.getWorksheet(record.sheet) !== undefined) {
                Object.entries(record.data)
                    .map(([k, v]) => this.writeValue(record.sheet, k.toUpperCase(), v));
            }
        });
    }

    loadTableData(data) {
        data.map((record, r) => {
            record.map((val, c) => {
                this.writeValue('DATA', this.cell(r + 2, c + 1), val);
            });
        });
    }

    cell(r, c) {
        return this.numToCell(c) + r;
    }

    numToCell(n) {
        let right = n % 26,
            left = Math.floor(n - right) / 26;
        if ((right === 0) && (left > 0)) { 
            right += 26;
            left -= 1;
        }
        return this.letter(left) + this.letter(right);
    }

    letter(n) {
        return (n > 0) ? String.fromCharCode(n + 64) : '';
    }

    writeValue(sheet, cell, value) {
        this.workbook.getWorksheet(sheet).getCell(cell).value = value;
    }

    reOrder() {
        // Set temp id on each sheet
        Object.entries(this.workbook._worksheets).map(([k, v]) => (v.id = 'temp' + v.id));
        // Set correct order id on each sheet
        Object.entries(this.workbook._worksheets).map(([k, v]) => {
            sheetOrder.map((name, i) => {
                if (v.name === name) { v.id = i + 1; }
            });
            this.workbook._worksheets[v.id] = v;
        });
    }

    write(filename) {
        this.reOrder();
        const f = filename || this.makeFilename();
        return this.workbook.xlsx.writeFile(f);
    }

    makeFilename() {
        return new Date().toISOString().slice(0, 10) + '.xlsx';
    };

}

module.exports = ExcelService;
