const XLSX = require('xlsx');
const workbook = XLSX.readFile('./app/excel/templates/dpa-return-unprotected.xlsx');

// const Excel = require('exceljs');
// const Workbook = new Excel.Workbook();

module.exports = {

    // read: (filename) => {
    //     return Workbook.xlsx.readFile(filename);
    // },

    listTabs: (book) => {
        return book.SheetNames;
    },

    // Returns first worksheet with name 
    // containing input name, or null
    firstSheetWithName: (name) => {
        let n = workbook.SheetNames.filter(n => n.indexOf(name) > -1);
        if (n.length === 0) return null;
        return workbook.Sheets[n[0]];
    },

    getCell: (sheet, ref) => {
        return sheet[ref];
    },

    getCellValue: (sheet, ref) => {
        let cell = sheet[ref];
        return cell ? cell.v : undefined;
    },

    setCellValue: (sheet, ref, value) => {
        if (!sheet[ref]) { sheet[ref] = {}; }
        sheet[ref].v = value;
    },

    // getCellValue: (workbook, sheet, ref) => {
    //     return workbook.getWorksheet(sheet).getCell(ref).value
    // },

    // setCellValue: (workbook, sheet, ref, value) => {
    //     workbook.getWorksheet(sheet).getCell(ref).value = value;
    // },

    // reorderSheets: (workbook, order) => {
    //     let temp = workbook.worksheets;
    //     for (let i = 0; i < order.length; i++) {
    //         let next = order.indexOf(i);
    //         console.log(temp[next].name)
    //         workbook.worksheets[i] = temp[next];
    //         console.log(workbook.worksheets[i].name)
    //     }
    //     return workbook;
    // },

    write: (/*workbook, filename*/) => {
        let wopts = { bookType: 'xlsx', bookSST: false, type: 'binary' };
        XLSX.writeFile(workbook, 'out.xlsx', wopts);
        return false;
        // return workbook.xlsx.writeFile(filename);
    }

}

