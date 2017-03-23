const XLSX = require('xlsx');
let workbook;

const makeFilename = () => {
    return new Date().toISOString().slice(0, 10) + '.xlsx';
};

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
};

const getRange = (r) => {
    let range = XLSX.utils.decode_range(r),
        collection = [];
    for (let R = range.s.r; R <= range.e.r; ++R) {
        for (let C = range.s.c; C <= range.e.c; ++C) {
            collection.push({ c: C, r: R });
        }
    }
    return collection;
};

const setRange = (r, data) => {
    console.log(getRange(r))
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