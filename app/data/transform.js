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

const combiners = {
    'and': (args) => { return args.reduce((a, b) => a && b); },
    'or': (args) => { return args.reduce((a, b) => a || b); }
};

const removeQuotes = (text) => {
    return text.replace(/'/g, "").replace(/"/g, "");
}

const filterFloat = (value) => {
    if (/^(\-|\+)?([0-9]+(\.[0-9]+)?|Infinity)$/
        .test(value))
        return Number(value);
    return removeQuotes(value);
}

let cast = (text) => {
    return filterFloat(text);
}

const hasNoBrackets = (text) => {
    return (text.indexOf('(') === -1) && (text.indexOf(')') === -1);
}

// Split input expression into three parts
const makeFunction = (expression) => {
    let parts = expression.split(' ').filter(p => p.length > 0);
    if (parts.length < 3) return null;
    let a = cast(parts[0]),
        f = operators[parts[1].toLowerCase()],
        b = cast(parts.slice(2, parts.length).join(' '));    // Combine any parts after 2
    return { f, a, b };
}

const evaluate = (params, arr) => {
    let { f, a, b } = params;
    if (arr && arr[a]) return f(arr[a], b);
    return f(a, b);
}

const evalWrap = (f) => {
    return (arr) => evaluate(f, arr);
}

const combine = (functions, op) => {
    return (arr) => combiners[op](functions.map(f => f(arr)));
}

const simplifyBrackets = (expression) => {
    var a = [], r = [], combiners = [], lastClose = 0, level = 0, depth = { max: 0, min: Infinity };
    for (var i = 0; i < expression.length; i++) {
        if (expression.charAt(i) == '(') {
            let ex = expression.substring(lastClose + 1, i).trim();
            if ((ex.length > 0) && (hasNoBrackets(ex))) { combiners.push({ l: level, op: ex.trim() }); }
            level++;
            a.push(i);
        }
        if (expression.charAt(i) == ')') {
            lastClose = i;
            level--;
            let ex = expression.substring(a.pop() + 1, i).trim();
            if (hasNoBrackets(ex)) {
                depth.min = Math.min(depth.min, level);
                depth.max = Math.max(depth.max, level);
                r.push({
                    l: level,
                    fn: makeFunction(ex),
                    eval: evalWrap(makeFunction(ex))
                });
            }
        }
    }
    return {
        functions: r,
        combiners: combiners,
        depth: depth
    };
}

const evaluateTree = (tree) => {
    let d = tree.depth,
        f = tree.functions,
        combineList = [],
        nextLevel = [];
    for (let i = 0; i < f.length; i++) {
        if (f[i].l === d.max) {
            while (f[i].l === d.max) {
                combineList.push((f[i].eval) ? f[i].eval : f[i].c);     // Push simple or combined function
                i++;
            }
            nextLevel.push({ l: d.max - 1, c: combine(combineList, 'or') });    // Might play up for long chains!
            combineList = [];
        }
        nextLevel.push(f[i]);
    }
    console.log(nextLevel);
}

// Public Class
module.exports = class Transform {

    constructor() {
        this.data = null;
        this.error = null;
        this.lastResult = [];
    }

    load() {
        return eclipse.getTestData().then(d => this.data = d).catch(e => this.error = e);
    }

    query(expression) {
        this.lastResult = this.data.filter(row => evaluate(makeFunction(expression), row));
        return this.lastResult;
    }

    count() {
        return this.lastResult.length;
    }

}