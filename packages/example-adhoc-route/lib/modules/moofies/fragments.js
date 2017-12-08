/*

Register the GraphQL fragment used to query for data

*/

import { registerFragment } from 'meteor/vulcan:core';

registerFragment(`
  fragment MoofiesItemFragment on Moofie {
    _id
    createdAt
    userId
    user {
      displayName
    }
    name
    year
    review
  }
`);

registerFragment(`
  fragment MoofiePageFragment on Moofie {
    _id
    createdAt
    userId
    user {
      displayName
    }
    name
    year
    slug
    review
  }
`);
