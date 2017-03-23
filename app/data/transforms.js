const eclipse = require('./eclipse-service');

module.exports = class Transforms {

    constructor() {
        this.data = null;
        this.error = null;
    }

    load() {
        return eclipse.getTestData().then(d => this.data = d).catch(e => this.error = e);
    }

}