let chai = require('chai');
let chaiHttp = require('chai-http');
let chaiJSON = require('chai-json');
var expect = chai.expect;
let should = chai.should();
var assert = chai.assert;


chai.use(chaiHttp);
chai.use(chaiJSON);

const url = 'http://localhost:9080';

// Test / route
describe('/GET /metrics',() => {
    it('should return 200', (done) => {
        chai.request(url)
            .get('/metrics')
            .end((err,res) => {
                res.should.have.status(200);
            done();
        });
    });
});