import request from 'supertest';  // HTTP assertions
import { expect } from 'chai';    // Assertions
import app from '../app.js';      // Import the app

let server;

describe('GET /', function () {
  before((done) => {
    // Start the server before running tests, on a dynamic port
    server = app.listen(0, () => {
      console.log(`Test server running at http://localhost:${server.address().port}`);
      done();
    });
  });

  it('should return 200 and the correct message', function (done) {
    request(app)
      .get('/')
      .expect(200) // Assert status is 200
      .end((err, res) => {
        if (err) return done(err);
        expect(res.text).to.equal('hello, my name is Ariane'); // Assert response text
        done();
      });
  });

  after((done) => {
    // Close the server after tests
    if (server) {
      server.close(() => {
        console.log('Test server closed');
        done();
      });
    } else {
      done();
    }
  });
});

