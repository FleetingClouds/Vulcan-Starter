'use strict';

import Sequelize from 'sequelize';

const sequelize = new Sequelize(
  'examples',
  null,
  null,
  {
    dialect: "sqlite",
    logging: false,
    storage: './.example.sqlite',
  },
);


sequelize.authenticate()
.then(function(err) {
    console.log('Connection has been established successfully.');
  }, function (err) {
    console.log('Unable to connect to the database:', err);
  }
);



const sanityCheck = (table, label, attribute, row) => {

  table.findAll().then(function (result) {
    console.log(' %s #%s -- %s', label, row + 1, result[row][attribute]); // eslint-disable-line no-console
  }).catch( (error) => {
    console.log('Sequelize error while finding sanity check item...', error); // eslint-disable-line no-console
  });

}

export { Sequelize, sequelize, sanityCheck };
