const XLSX = require('xlsx');
let workbook;

const makeFilename = () => {
    return new Date().toISOString().slice(0, 10) + '.xlsx';
};

module.exports = {

    read: (filename) => {
        // let opts = { cellStyles: true };
        let opts = {};
        workbook = XLSX.readFile(filename, opts);
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

    getRange: (r) => {
        let range = XLSX.utils.decode_range(r),
            collection = [];
        for (let R = range.s.r; R <= range.e.r; ++R) {
            for (let C = range.s.c; C <= range.e.c; ++C) {
                collection.push({ c: C, r: R });
            }
        }
        return collection;
    },

    setRange: (r, data) => {

    },

    write: (filename) => {
        if (!filename) { filename = makeFilename(); }
        XLSX.writeFile(workbook, filename);
    }

}

