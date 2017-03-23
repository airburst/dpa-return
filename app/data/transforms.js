const eclipse = require('./eclipse-service');

const operators = {
    'eq': (a, b) => { return a === b; },
    'ne': (a, b) => { return a !== b; },
    'lt': (a, b) => { return a < b; },
    'le': (a, b) => { return a <= b; },
    'gt': (a, b) => { return a > b; },
    'ge': (a, b) => { return a >= b; },
    'inc': (a, b) => { return a.indexOf(b) > -1; },
    'exc': (a, b) => { return a.indexOf(b) === -1; }
};

let isNumber = (text) => {
    return typeof (text) === 'number';
}

let castNum = (text) => {
    return parseFloat(text, 10);
}

let cast = (text) => {
    return isNumber(text) ? castNum(text) : text;
}

const parseExpression = (expression) => {
    let parts = expression.split(' ').filter(p => p.length > 0);
    if (parts.length !== 3) return false;
    let a = cast(parts[0]),
        f = operators[parts[1]],
        b = cast(parts[2]);
    return { f, a, b };
}

// Public Class
module.exports = class Transform {

    constructor() {
        this.data = null;
        this.error = null;
    }

    load() {
        return eclipse.getTestData().then(d => this.data = d).catch(e => this.error = e);
    }

    query(expression) {
        let { f, a, b } = parseExpression(expression);
        console.log(f, a, b)                            //
        return this.data.filter(row => f(row[a], b));
    }

    count(criteria) {
        return 0;
    }

}