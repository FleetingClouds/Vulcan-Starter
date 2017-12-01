import { sequelize as sqlz } from '../../db_connectors';

import { modelName, model } from './model';
import seeds from './seeds.json';

const collection = sqlz.import(modelName.l, model);
collection.sync();

// console.log(' Within %s == this\n', module.id, this);

const controller = {
  /* eslint-disable no-console */

  collection: collection,

  seed: () => {

    collection.findAndCountAll({}).then( (rslt) => {
      if ( rslt.count < 1 ) {
        console.log('<|| creating dummy moofies ||>');
        seeds.data.forEach( document => {
          console.log(' Create :: ', document);
          controller.create( null, document );
        });
      } else {
        console.log(' Moofies seeded already.');
      }
    });
  },

  findAndCountAll: (_, args) => {

    // newMutation({
    //   action: 'moofies.new',
    //   collection: Moofies,
    //   document: document,
    //   currentUser: currentUser,
    //   validate: false
    // });

    return collection.findAndCountAll({})
//     .then(
//      (sequelizeResult) => {
//       const { errors, dataValues } = sequelizeResult;
//       if (dataValues) {
// //        console.log('%s, "%s", has data values :: %s', modelName.t, args.name, dataValues);
//         return dataValues;
//       }
//       if (errors) {
//         console.log('Sequelize error while retrieving the %s, "%s"', modelName.l, args.name);
//         console.log('Error : ', errors);
//       }
//     }).catch( (error) => {
//       console.log('Sequelize error while creating the %s, "%s"', modelName.l, args.name);
//       console.log('Error : ', error);
//     });
  },

  create: (_, args) => {

    // newMutation({
    //   action: 'moofies.new',
    //   collection: Moofies,
    //   document: document,
    //   currentUser: currentUser,
    //   validate: false
    // });

    return collection.create({
      name: args.name,
      slug: args.slug,
      year: args.year,
      review: args.review,
      privateComments: args.privateComments,
    }).then( (sequelizeResult) => {
      const { errors, dataValues } = sequelizeResult;
      if (dataValues) {
//        console.log('%s, "%s", has data values :: %s', modelName.t, args.name, dataValues);
        return dataValues;
      }
      if (errors) {
        console.log('Sequelize error while retrieving the %s, "%s"', modelName.l, args.name);
        console.log('Error : ', errors);
      }
    }).catch( (error) => {
      console.log('Sequelize error while creating the %s, "%s"', modelName.l, args.name);
      console.log('Error : ', error);
    });
  },
  /* eslint-enable no-console */
};

export default controller;
