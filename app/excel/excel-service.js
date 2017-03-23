const XLSX = require('xlsx');
let workbook;

const makeFilename = () => {
    return new Date().toISOString().slice(0, 10) + '.xlsx';
};

const isUnbound = (range) => {
    return ((range.s.r === NaN) || (range.e.r === NaN) || (range.s.c === NaN) || (range.e.c === NaN));
}


const read = (filename) => {
    // let opts = { cellStyles: true };
    let opts = {};
    workbook = XLSX.readFile(filename, opts);
};

const firstSheetWithName = (name) => {
    let n = workbook.SheetNames.filter(n => n.indexOf(name) > -1);
    if (n.length === 0) return null;
    return workbook.Sheets[n[0]];
};

const getCellValue = (sheet, ref) => {
    let cell = sheet[ref];
    return cell ? cell.v : undefined;
};

const setCellValue = (sheet, ref, value) => {
    if (!sheet[ref]) { sheet[ref] = {}; }
    sheet[ref].v = value;
    if (typeof (value) === 'number') { sheet[ref].t = 'n'; }    // Set cell type to number
};

const getRange = (r) => {
    if (!r) return null;
    if (typeof (r) !== 'string') return null;
    return XLSX.utils.decode_range(r);
};

const setRange = (s, r, data) => {
    let range = getRange(r);
    if (range && !isUnbound(range)) {
        let row = 0;
        for (let R = range.s.r; R <= range.e.r; ++R) {
            let col = 0;
            for (let C = range.s.c; C <= range.e.c; ++C) {
                if (data[row] && data[row][col]) {
                    let cell = XLSX.utils.decode_cell({ c: C, r: R });
                    console.log('Setting', cell, data[row][col]);                   //
                    setCellValue(s, cell, data[row][col++]);
                }
                row++;
            }
        }
    }
};

const write = (filename) => {
    if (!filename) { filename = makeFilename(); }
    XLSX.writeFile(workbook, filename);
};

/* Public Methods */
module.exports = {
    read: read,
    firstSheetWithName: firstSheetWithName,
    getCellValue: getCellValue,
    setCellValue: setCellValue,
    getRange: getRange,
    setRange: setRange,
    write: write
}