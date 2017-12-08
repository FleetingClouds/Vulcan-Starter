import { sequelize as sqlz } from '../../db_connectors';

import { modelName, model } from './model';
import seeds from './seeds.json';

const LG = (msg) => console.log('Within %s...\n  |%s', module.id, msg);
const MRK = (chr, cnt) => console.log(chr.repeat(cnt));


const collection = sqlz.import(modelName.l, model);
collection.sync();

  // MRK('%', 10);
  // console.log(sqlz);
  // MRK('-', 10);
  // console.log(collection.findAndCountAll({}));
  // MRK('=', 10);

const controller = {
  /* eslint-disable no-console */

  collection: collection,

  seed: () => {

    const rows = Promise.await(
      collection.findAndCountAll({})
      .then( rslt => {
        let cnt = rslt.count;
        if ( cnt < 1 ) {
          console.log('<|| creating dummy moofies ||>');
          seeds.data.forEach( document => {
            console.log(' Create :: ', document);
            controller.create( null, document );
            cnt++;
          });
        } else {
          console.log(' Moofies seeded already.');
        }
        return cnt;
      })
    );
    console.log(' Rows :: ', rows);
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
