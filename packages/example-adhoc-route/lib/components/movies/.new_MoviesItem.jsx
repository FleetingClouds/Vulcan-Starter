/*

An item in the movies list.
Wrapped with the "withCurrentUser" container.

*/

import React from 'react';
import { Components, registerComponent } from 'meteor/vulcan:core';
import { withRouter } from 'react-router';

import Movies from '../../modules/movies/collection.js';

const MoviesItem = ({  loading, router  }) => {

    var movie = Movies.find({ name: router.location.query.name }).fetch()[0];
    console.log(  movie );
    return (
      <div>
        <div> name : { router.location.query.name }</div>
        <div> year : { movie.year }</div>
        <div> review : { movie.review }</div>
      </div>
    );
}

registerComponent('MoviesItem', withRouter(MoviesItem));
