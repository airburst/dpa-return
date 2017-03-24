const Transform = require('./data/transform');
const excel = require('./excel/excel-service');

let transform = new Transform();

const handleError = (e) => {
    console.log(e);
    return null;
}

const getData = () => {
    return transform.load()
        .then(results => { return results; })
        .catch(handleError);
}

const processData = () => {
    // The run sequence of actions
    excel.read('./app/excel/templates/dpa-template.xlsx');
    let count = transform.query('age gt 65').length;
    console.log(count);

    let data = transform.query('dparequestedstartdate ge 2016-10-01')
    console.log(transform.count());

    // etc..
    let sheet = new excel.sheet('DPA001');
    let colWidths = [
        { width: 10, wpx: 10 },
        { width: 50, wpx: 50 },
    ];
    excel.setColsForSheet(sheet, colWidths);
    console.log(sheet['!cols'])

    // let style = {fill: { patternType: "solid", bgColor: { theme: 5, tint: -0.20}, fgColor: "FFFFFFFF"}};
    // sheet.setStyle('B3', style);

    excel.write();
}

// Do the run sequence (async, once data is returned)
module.exports = {
    run: () => { getData().then(processData).catch(handleError); }
};