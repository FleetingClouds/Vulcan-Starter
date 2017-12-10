/*

Seed the database with some dummy content.

*/

import Movies from '../modules/movies/collection.js';
import Moofies from '../modules/moofies/collection.js';

import Users from 'meteor/vulcan:users';
import { newMutation } from 'meteor/vulcan:core';
import seed from './seed.json';

const LG = (ln, msg) => console.log('Within %s @ %s ...\n  | %s', module.id, ln, msg);
const MRK = (chr, cnt) => console.log(chr.repeat(cnt));

const createUser = function (username, email) {
  const user = {
    username,
    email,
    isDummy: true
  };
  newMutation({
    collection: Users,
    document: user,
    validate: false
  });
}

var createDummyUsers = function () {
  console.log('// inserting dummy users…');
  createUser('Bruce', 'dummyuser1@telescopeapp.org');
  createUser('Arnold', 'dummyuser2@telescopeapp.org');
  createUser('Julia', 'dummyuser3@telescopeapp.org');
};

Meteor.startup(function () {

  if (Users.find().fetch().length === 0) {
    createDummyUsers();
  }

  while (  Users.find().count() < 3 ) {
    Meteor._sleepForMs(500);
  };

  const currentUser = Users.findOne(); // just get the first user available
  if (Movies.find().fetch().length === 0) {
    console.log('// creating dummy movies');
    seed.data.forEach(document => {
      newMutation({
        action: 'movies.new',
        collection: Movies,
        document: document,
        currentUser: currentUser,
        validate: false
      });
    });
  } else {
    console.log(' Movies seeded already.');
  }

  // MRK('  .  ', 20);
  // LG(83, Moofies.find().fetch());
  if (Moofies.find().fetch().length < 5) {
    console.log('// creating dummy moofies');
    seed.data.forEach(document => {
      // console.log(document);
      newMutation({
        action: 'moofies.new',
        collection: Moofies,
        document: document,
        currentUser: currentUser,
        validate: false
      });
    });
  } else {
    console.log(' Moofies seeded already.');
  }

});
