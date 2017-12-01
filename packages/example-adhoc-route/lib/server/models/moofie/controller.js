import { modelName, ormKit } from './index';

export default {
  /* eslint-disable no-console */
  findAndCountAll: (_, args) => {

    // newMutation({
    //   action: 'movies.new',
    //   collection: Movies,
    //   document: document,
    //   currentUser: currentUser,
    //   validate: false
    // });

    return ormKit.db.findAndCountAll({})
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
    //   action: 'movies.new',
    //   collection: Movies,
    //   document: document,
    //   currentUser: currentUser,
    //   validate: false
    // });

    return ormKit.db.create({
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
