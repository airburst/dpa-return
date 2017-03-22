const XLSX = require('xlsx');
let workbook;

const makeFilename = () => {
    return new Date().toISOString().slice(0, 10) + '.xlsx';
};

module.exports = {

    read: (filename) => {
        workbook = XLSX.readFile(filename);
    },

    // Returns first worksheet with name 
    // containing input name, or null
    firstSheetWithName: (name) => {
        let n = workbook.SheetNames.filter(n => n.indexOf(name) > -1);
        if (n.length === 0) return null;
        return workbook.Sheets[n[0]];
    },

    getCellValue: (sheet, ref) => {
        let cell = sheet[ref];
        return cell ? cell.v : undefined;
    },

    setCellValue: (sheet, ref, value) => {
        if (!sheet[ref]) { sheet[ref] = {}; }
        sheet[ref].v = value;
    },

    write: (filename) => {
        if (!filename) { filename = makeFilename(); }
        let wopts = { bookType: 'xlsx', bookSST: false, type: 'binary' };
        XLSX.writeFile(workbook, filename, wopts);
    }

}

