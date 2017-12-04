/*

The main Moofies collection definition file.

*/

import { createCollection } from 'meteor/vulcan:core';
import schema from './schema.js';
import models from '../../server/models';
// import resolvers from './resolvers.js';
// import './fragments.js';
// import mutations from './mutations.js';
// import './permissions.js';
// import './parameters.js';

console.log('Within %s \nMoofie ormKit :: ', module.id, models.moofie.ormKit);

const Moofies = createCollection({

  generateGraphQLSchema: false,

  collectionName: 'Moofies',

  typeName: 'Moofie',

  schema,

  // ormKit: models.moofie.ormKit,

  // resolvers,

  // mutations,

});

export default Moofies;
