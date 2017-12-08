/*

The main Moofies collection definition file.

*/

import { createCollection } from 'meteor/vulcan:core';
import schema from './schema.js';
import models from '../../server/models';
import resolvers from './resolvers.js';
import './fragments.js';
import mutations from './mutations.js';
import './permissions.js';
import './parameters.js';

const LG = (ln, msg) => console.log('Within %s @ %s ...\n  | %s', module.id, ln, msg);
const MRK = (chr, cnt) => console.log(chr.repeat(cnt));

const ormCollection = models.moofie.controller.collection;

    // LG(21, 'ormCollection');
    // console.log(ormCollection);
    // MRK('|', 10);

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
