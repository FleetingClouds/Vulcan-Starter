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

    let rslt = collection.findAndCountAll({});
    if ( rslt.count < 1 ) {
      console.log('<|| creating dummy moofies ||>');
      seeds.data.forEach( document => {
        console.log(' Create :: ', document);
        controller.create( null, document );
      });
    } else {
      console.log(' Moofies seeded already.');
    }

  },

  findAndCountAll: (_, args) => {

    return collection.findAndCountAll({})

  },

  create: (_, args) => {

    // newMutation({
    //   action: 'moofies.new',
    //   collection: Moofies,
    //   document: document,
    //   currentUser: currentUser,
    //   validate: false
    // });

    const sequelizeResult = collection.create({
      name: args.name,
      slug: args.slug,
      year: args.year,
      review: args.review,
      privateComments: args.privateComments,
    });

    const { errors, dataValues } = sequelizeResult;
    if (dataValues) {
      console.log('%s, "%s", has data values :: %s', modelName.t, args.name, dataValues);
      return dataValues;
    }

    console.log('Sequelize error while retrieving the %s, "%s"', modelName.l, args.name);
    console.log('Error : ', errors);

   },
  /* eslint-enable no-console */
};

export default controller;
