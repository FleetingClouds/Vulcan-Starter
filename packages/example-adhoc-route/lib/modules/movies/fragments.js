/*

Register the GraphQL fragment used to query for data

*/

import { registerFragment } from 'meteor/vulcan:core';

registerFragment(`
  fragment MoviesItemFragment on Movie {
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
  fragment MoviePageFragment on Movie {
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
