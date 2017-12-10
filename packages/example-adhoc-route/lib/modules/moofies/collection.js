/*

The main Moofies collection definition file.

*/

import { createCollection } from 'meteor/vulcan:core';
import schema from './schema.js';
import resolvers from './resolvers.js';
import './fragments.js';
import mutations from './mutations.js';
import './permissions.js';
import './parameters.js';

import { ormCollection } from './api';

const LG = (ln, msg) => console.log('Within %s @ %s ...\n  | %s', module.id, ln, msg);
const MRK = (chr, cnt) => console.log(chr.repeat(cnt));

const Moofies = createCollection({

//  generateGraphQLSchema: false,

  collectionName: 'Moofies',

  typeName: 'Moofie',

  schema,

  ormCollection,

  resolvers,

  mutations,

});

export default Moofies;
