const Excel = require('exceljs');
const sheetOrder = [
    'Cover',
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

    write(filename) {
        this.reOrder();
        const f = filename || this.makeFilename();
        return this.workbook.xlsx.writeFile(f);
    }

    makeFilename() {
        return new Date().toISOString().slice(0, 10) + '.xlsx';
    };

    listSheets(workbook) {
        this.workbook.eachSheet((sheet, id) => (console.log(id, sheet.name)));
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

}

module.exports = ExcelService;