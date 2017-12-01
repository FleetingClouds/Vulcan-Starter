/* jshint indent: 2 */

import { sequelize } from '../../db_connectors';

import controller from './controller';
import model from './model';
import seed from './seed';

let modelName = { t: 'Moofie' };

modelName.u = modelName.t.toUpperCase();
modelName.l = modelName.t.toLowerCase();

const db = sequelize.import(modelName.l, model);

// console.log(' in moofie/index >> model:', model);
// console.log(' in moofie/index >> db:', db);

//  SYNC SCHEMA
db
  .sync({ force: false })
  .then(function(err) {
    console.log('Test data has been installed!');
  }, function (err) {
    console.log('An error occurred while creating the table:', err);
  });

const ormKit = { db, model };

controller.seed = seed;

// export { modelName, ormKit, controller, seed };
export { modelName, ormKit, controller };
