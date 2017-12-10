import { Components, registerComponent } from 'meteor/vulcan:core';
import React from 'react';

const MoviesGet = (props, context) => {
  let adhoc = `{ "slug": "` + props.params.slug + `"  }`;
  return <Components.MoviePage slug={adhoc} />
};

MoviesGet.displayName = "MoviesGet";

registerComponent('MoviesGet', MoviesGet);
